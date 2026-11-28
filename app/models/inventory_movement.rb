# Every change to an ingredient's stock, signed (negative = goes out).
class InventoryMovement < ApplicationRecord
  KINDS = {
    "venta"             => "Venta",
    "devolucion"        => "Devolución (regresa al stock)",
    "devolucion_merma"  => "Devolución ya preparada (merma)",
    "merma"             => "Merma",
    "compra"            => "Compra",
    "ajuste"            => "Ajuste manual",
    "carga_inicial"     => "Carga inicial desde Matriz"
  }.freeze

  belongs_to :ingredient
  belongs_to :user, optional: true
  belongs_to :order, optional: true
  belongs_to :order_item, optional: true

  validates :kind, inclusion: { in: KINDS.keys }

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def kind_label
    KINDS[kind] || kind
  end
end
