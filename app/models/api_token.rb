require "digest"
require "securerandom"

class ApiToken < ApplicationRecord
  VALID_SCOPES = %w[read write].freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(revoked_at: nil) }

  def self.authenticate(raw_token)
    return nil if raw_token.blank?
    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  # Builds a new ApiToken with a fresh raw token. Caller must save it and show
  # the raw value ONCE — we only persist the SHA256 digest.
  def self.build_with_token(attrs = {})
    raw = "endx_#{SecureRandom.hex(24)}"
    token = new(attrs.merge(token_digest: digest(raw)))
    [ token, raw ]
  end

  def scope_list
    scopes.to_s.split(",").map(&:strip)
  end

  def can?(scope)
    return false if revoked_at
    scope_list.include?(scope.to_s)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def touch_usage!
    update_columns(last_used_at: Time.current)
  end
end
