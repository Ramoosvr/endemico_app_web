class User < ApplicationRecord
  ROLES = %w[admin barista].freeze

  has_secure_password

  normalizes :name, with: ->(name) { name.strip.downcase }

  has_many :orders, dependent: :nullify
  has_many :agent_messages, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  scope :admins,   -> { where(role: "admin") }
  scope :baristas, -> { where(role: "barista") }

  def admin?
    role == "admin"
  end

  def barista?
    role == "barista"
  end
end
