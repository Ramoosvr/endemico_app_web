class OptionGroup < ApplicationRecord
  SELECTION_MODES = %w[single multiple].freeze

  belongs_to :product
  has_many :option_choices, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :option_group

  accepts_nested_attributes_for :option_choices, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :selection_mode, inclusion: { in: SELECTION_MODES }

  scope :ordered, -> { order(:position, :id) }

  def single?   = selection_mode == "single"
  def multiple? = selection_mode == "multiple"
end
