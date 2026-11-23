require "net/http"
require "json"
require "uri"

class ClaudeAgent
  class NotConfigured < StandardError; end
  class APIError < StandardError; end

  API_URL = URI("https://api.anthropic.com/v1/messages").freeze
  MAX_TOOL_ITERATIONS = 6
  MAX_TOKENS = 2048
  ANTHROPIC_VERSION = "2023-06-01".freeze

  def initialize(user)
    @user = user
    @api_key = Setting.get(:ai_api_key).to_s
    @model   = Setting.get(:ai_model).to_s.presence || "claude-sonnet-4-6"
    @system  = Setting.get(:ai_system_prompt).to_s
    @enabled = Setting.get(:ai_enabled)
  end

  def send_user_message!(text)
    raise NotConfigured, "El agente de IA está desactivado. Actívalo en Ajustes." unless @enabled
    raise NotConfigured, "Falta la API key de Claude. Configúrala en Ajustes." if @api_key.blank?

    @user.agent_messages.create!(role: "user", content: text)
    run_turn!
  end

  def reset!
    @user.agent_messages.delete_all
  end

  private

  def run_turn!
    iterations = 0

    loop do
      iterations += 1
      raise APIError, "Loop de tool-use excedió el máximo (#{MAX_TOOL_ITERATIONS})." if iterations > MAX_TOOL_ITERATIONS

      response = call_api(build_messages)
      content_blocks = response["content"] || []

      text_blocks = content_blocks.select { |b| b["type"] == "text" }
      tool_uses   = content_blocks.select { |b| b["type"] == "tool_use" }

      assistant_text = text_blocks.map { |b| b["text"] }.join("\n\n").strip

      if tool_uses.any?
        assistant_payload = { "content" => content_blocks }
        @user.agent_messages.create!(
          role: "assistant",
          content: assistant_text,
          tool_payload_hash: assistant_payload
        )

        tool_results_blocks = tool_uses.map do |tu|
          result = AgentTools.run(tu["name"], tu["input"] || {})
          {
            "type" => "tool_result",
            "tool_use_id" => tu["id"],
            "content" => result.to_json
          }
        end

        tool_payload = {
          "content" => tool_results_blocks,
          "calls"   => tool_uses.map { |tu| { "id" => tu["id"], "name" => tu["name"], "input" => tu["input"] } }
        }

        @user.agent_messages.create!(
          role: "tool",
          content: tool_uses.map { |tu| tu["name"] }.join(", "),
          tool_payload_hash: tool_payload
        )
      else
        @user.agent_messages.create!(role: "assistant", content: assistant_text)
        return assistant_text
      end

      break if response["stop_reason"] == "end_turn" && tool_uses.empty?
    end
  end

  def build_messages
    msgs = []
    @user.agent_messages.ordered.each do |m|
      case m.role
      when "user"
        msgs << { role: "user", content: [ { type: "text", text: m.content } ] }
      when "assistant"
        payload = m.tool_payload_hash
        if payload["content"].present?
          msgs << { role: "assistant", content: payload["content"] }
        else
          msgs << { role: "assistant", content: [ { type: "text", text: m.content } ] }
        end
      when "tool"
        payload = m.tool_payload_hash
        msgs << { role: "user", content: payload["content"] } if payload["content"].present?
      end
    end
    msgs
  end

  def call_api(messages)
    body = {
      model: @model,
      max_tokens: MAX_TOKENS,
      system: [
        {
          type: "text",
          text: @system,
          cache_control: { type: "ephemeral" }
        }
      ],
      tools: AgentTools.definitions,
      messages: messages
    }

    req = Net::HTTP::Post.new(API_URL)
    req["x-api-key"] = @api_key
    req["anthropic-version"] = ANTHROPIC_VERSION
    req["content-type"] = "application/json"
    req.body = body.to_json

    http = Net::HTTP.new(API_URL.host, API_URL.port)
    http.use_ssl = true
    http.read_timeout = 60
    http.open_timeout = 15

    res = http.request(req)

    unless res.is_a?(Net::HTTPSuccess)
      error_detail = begin
        JSON.parse(res.body).dig("error", "message")
      rescue
        res.body
      end
      raise APIError, "Claude respondió #{res.code}: #{error_detail}"
    end

    JSON.parse(res.body)
  end
end
