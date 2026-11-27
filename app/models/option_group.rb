class OptionGroup < ApplicationRecord
  SELECTION_MODES = %w[single multiple counter].freeze
  SIZE_NAMES = [ "tamaño", "tamano" ].freeze

  belongs_to :product
  has_many :option_choices, -> { where(active: true).order(:position, :id) }, dependent: :destroy, inverse_of: :option_group

  accepts_nested_attributes_for :option_choices, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :selection_mode, inclusion: { in: SELECTION_MODES }

  scope :ordered, -> { order(:position, :id) }

  def single?   = selection_mode == "single"
  def multiple? = selection_mode == "multiple"
  # "− n +" stepper. With one choice it is a plain counter ("Shot extra");
  # with several, the choices are the flavor to pick ("Pump extra: Vainilla").
  def counter?  = selection_mode == "counter"

  # Size groups ("Tamaño") show as big buttons with the full price.
  def size? = single? && SIZE_NAMES.include?(name.to_s.strip.downcase)

  # The choice preselected in the pop-up: the default one if it is available,
  # otherwise the first available one for required groups.
  def preselected_choice
    available = option_choices.select(&:available)
    available.find(&:default_selected) || (required && single? ? available.first : nil)
  end

  # Required groups go at the top of the pop-up; the rest go under "Extras".
  def extra? = counter? || !required
end
