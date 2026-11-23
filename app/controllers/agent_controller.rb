class AgentController < ApplicationController
  before_action :require_admin!

  def index
    @messages = current_user.agent_messages.ordered.where(role: [ "user", "assistant" ])
    @enabled  = Setting.get(:ai_enabled)
    @api_key_set = Setting.get(:ai_api_key).to_s.present?
    @model    = Setting.get(:ai_model)
  end

  def create
    text = params[:message].to_s.strip
    if text.blank?
      redirect_to agente_path and return
    end

    agent = ClaudeAgent.new(current_user)
    agent.send_user_message!(text)
    redirect_to agente_path
  rescue ClaudeAgent::NotConfigured => e
    redirect_to ajustes_path, alert: e.message
  rescue ClaudeAgent::APIError => e
    current_user.agent_messages.create!(role: "assistant", content: "⚠ #{e.message}")
    redirect_to agente_path
  rescue => e
    Rails.logger.error("[Agent] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    current_user.agent_messages.create!(role: "assistant", content: "⚠ Error inesperado: #{e.message}")
    redirect_to agente_path
  end

  def destroy
    current_user.agent_messages.delete_all
    redirect_to agente_path, notice: "Conversación reiniciada."
  end
end
