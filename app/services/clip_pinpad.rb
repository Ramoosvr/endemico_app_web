require "net/http"
require "json"
require "uri"
require "base64"

class ClipPinpad
  class NotConfigured < StandardError; end
  class APIError < StandardError
    attr_reader :status, :body
    def initialize(msg, status: nil, body: nil)
      super(msg)
      @status = status
      @body = body
    end
  end

  def initialize
    @token  = Setting.get(:clip_api_token).to_s.strip
    @secret = Setting.get(:clip_secret_key).to_s.strip
    @serial = Setting.get(:clip_serial_number).to_s.strip
    @base   = Setting.get(:clip_base_url).to_s.strip.presence || "https://api.payclip.io"
  end

  def test_mode?
    @token.start_with?("test_")
  end

  def configured?
    @token.present? && @secret.present? && @serial.present?
  end

  # POST /f2f/pinpad/v1/payment
  def create_payment(amount:, reference:, description: nil, webhook_url: nil, success_url: nil, error_url: nil)
    ensure_configured!
    body = {
      amount: amount.to_f.round(2),
      currency: "MXN",
      serial_number: @serial,
      description: description.presence || "Pedido Endemico",
      external_reference: reference.to_s,
      tip_enabled: false,
      webhook_url: webhook_url.presence || "https://httpbin.org/post",
      redirect: {
        success_url: success_url.presence || "https://httpbin.org/get?status=success",
        error_url:   error_url.presence   || "https://httpbin.org/get?status=error"
      },
      preferences: {
        printer_enabled: true,
        tip_screen_enabled: false,
        signature_screen_enabled: false,
        amount_screen_enabled: true,
        nfc_enabled: true,
        msi_enabled: false,
        mci_enabled: false
      }
    }
    request(:post, "/f2f/pinpad/v1/payment", body: body)
  end

  # GET /f2f/pinpad/v1/payment/:id (consultar detalle)
  def get_payment(pinpad_request_id)
    ensure_configured!
    request(:get, "/f2f/pinpad/v1/payment/#{pinpad_request_id}")
  end

  # DELETE /f2f/pinpad/v1/payment/:id
  def cancel_payment(pinpad_request_id)
    ensure_configured!
    request(:delete, "/f2f/pinpad/v1/payment/#{pinpad_request_id}")
  end

  # GET /f2f/pinpad/v1/readers/status/:serial (status de lectores)
  def device_status
    ensure_configured!
    request(:get, "/f2f/pinpad/v1/readers/status/#{@serial}")
  end

  private

  def ensure_configured!
    return if configured?
    missing = []
    missing << "API key"      if @token.blank?
    missing << "Secret key"   if @secret.blank?
    missing << "N° de serie"  if @serial.blank?
    raise NotConfigured, "Faltan datos de Clip en Ajustes: #{missing.join(", ")}."
  end

  def request(method, path, body: nil, query: nil)
    uri = URI.join(@base, path)
    uri.query = URI.encode_www_form(query) if query.present?

    req = case method
          when :post   then Net::HTTP::Post.new(uri)
          when :get    then Net::HTTP::Get.new(uri)
          when :delete then Net::HTTP::Delete.new(uri)
          else raise ArgumentError, "método no soportado: #{method}"
          end

    req["Authorization"] = "Basic " + Base64.strict_encode64("#{@token}:#{@secret}")
    req["Content-Type"] = "application/json" if body
    req["Accept"] = "application/json"
    req.body = body.to_json if body

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 30

    res = http.request(req)
    parsed = parse_body(res.body)

    unless res.is_a?(Net::HTTPSuccess)
      msg = parsed.is_a?(Hash) ? (parsed["message"] || parsed["error"] || res.body) : res.body
      raise APIError.new("Clip respondió #{res.code}: #{msg}", status: res.code, body: parsed)
    end

    parsed
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise APIError.new("Clip no respondió a tiempo: #{e.message}")
  end

  def parse_body(raw)
    return {} if raw.blank?
    JSON.parse(raw)
  rescue JSON::ParserError
    raw
  end
end
