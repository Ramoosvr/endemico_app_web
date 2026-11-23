class AgentMessage < ApplicationRecord
  belongs_to :user

  ROLES = %w[user assistant tool].freeze
  validates :role, inclusion: { in: ROLES }

  scope :ordered, -> { order(:created_at) }

  def tool_payload_hash
    return {} if tool_payload.blank?
    JSON.parse(tool_payload)
  rescue JSON::ParserError
    {}
  end

  def tool_payload_hash=(h)
    self.tool_payload = h.to_json
  end
end
