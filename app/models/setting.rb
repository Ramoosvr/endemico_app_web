class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  DEFAULTS = {
    "coverage_days"            => "7",
    "purchase_day"             => "wednesday",
    "alert_threshold_percent"  => "25",
    "supplier_name"            => "",
    "supplier_whatsapp"        => "",
    "ai_enabled"               => "false",
    "ai_api_key"               => "",
    "ai_model"                 => "claude-sonnet-4-6",
    "ai_system_prompt"         => "Eres el agente de analisis de Endemico, una cafeteria. Ayuda al dueno a decidir compras, detectar tendencias de consumo y optimizar stock. Responde en espanol, breve y directo. Usa los tools disponibles para consultar datos reales antes de contestar.",
    "clip_api_token"           => "",
    "clip_secret_key"          => "",
    "clip_serial_number"       => "",
    "clip_base_url"            => "https://api.payclip.io",
    "clip_enabled"             => "false",
    "usd_rate"                 => "18.00",
    "refund_pin"               => ""
  }.freeze

  TYPED_KEYS = {
    "coverage_days"           => :integer,
    "alert_threshold_percent" => :integer,
    "ai_enabled"              => :boolean,
    "clip_enabled"            => :boolean,
    "usd_rate"                => :decimal
  }.freeze

  def self.get(key)
    raw = find_by(key: key.to_s)&.value
    raw = DEFAULTS[key.to_s] if raw.nil?
    cast(key.to_s, raw)
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.value = value.to_s
    record.save!
    record
  end

  def self.all_with_defaults
    stored = all.index_by(&:key)
    DEFAULTS.map { |k, default| [ k, stored[k]&.value || default ] }.to_h
  end

  def self.cast(key, raw)
    return nil if raw.nil?
    case TYPED_KEYS[key]
    when :integer then raw.to_i
    when :decimal then BigDecimal(raw.to_s)
    when :boolean then ActiveModel::Type::Boolean.new.cast(raw)
    else raw
    end
  end
end
