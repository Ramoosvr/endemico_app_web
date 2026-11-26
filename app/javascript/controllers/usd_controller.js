import { Controller } from "@hotwired/stimulus"

// Calcula el cambio en MXN cuando el barista teclea los USD recibidos.
// data-usd-total-value: total del pedido en MXN
// data-usd-rate-value:  MXN por 1 USD
export default class extends Controller {
  static targets = ["input", "change", "submit", "hint", "quick"]
  static values  = { total: Number, rate: Number }

  connect() {
    this.buildQuick()
    this.recalc()
  }

  buildQuick() {
    if (!this.hasQuickTarget) return
    const due = this.rateValue > 0 ? this.totalValue / this.rateValue : 0
    const presets = this.suggestions(due)
    this.quickTarget.innerHTML = presets.map(v =>
      `<button type="button" class="usd-quick-btn" data-action="click->usd#setAmount" data-amount="${v}">$${v}</button>`
    ).join("")
  }

  suggestions(due) {
    const bills = [1, 5, 10, 20, 50, 100]
    const set = new Set()
    for (const b of bills) {
      if (b >= due) set.add(b)
    }
    // añade combinaciones pequeñas que superen el mínimo
    const ceil = Math.ceil(due)
    set.add(ceil)
    if (ceil + 1 <= 100) set.add(ceil + 1)
    const sorted = Array.from(set).filter(v => v >= due).sort((a, b) => a - b).slice(0, 5)
    return sorted
  }

  setAmount(event) {
    this.inputTarget.value = event.currentTarget.dataset.amount
    this.inputTarget.focus()
    this.recalc()
  }

  recalc() {
    const usd = parseFloat(this.inputTarget.value || "0") || 0
    const mxnReceived = usd * this.rateValue
    const change = mxnReceived - this.totalValue

    if (usd <= 0) {
      this.changeTarget.textContent = this.fmtMxn(0)
      this.changeTarget.classList.remove("usd-row-value--short")
      this.hintTarget.textContent = "Ingresa los dólares recibidos para calcular el cambio."
      this.hintTarget.classList.remove("usd-hint--error")
      this.submitTarget.disabled = true
      return
    }

    if (change < 0) {
      const missingUsd = Math.abs(change) / this.rateValue
      this.changeTarget.textContent = `faltan ${this.fmtMxn(Math.abs(change))}`
      this.changeTarget.classList.add("usd-row-value--short")
      this.hintTarget.textContent = `Faltan ~$${missingUsd.toFixed(2)} USD más para cubrir el total.`
      this.hintTarget.classList.add("usd-hint--error")
      this.submitTarget.disabled = true
    } else {
      this.changeTarget.textContent = this.fmtMxn(change)
      this.changeTarget.classList.remove("usd-row-value--short")
      this.hintTarget.textContent = change > 0
        ? `Devuelve ${this.fmtMxn(change)} de cambio en pesos.`
        : "Monto exacto, sin cambio."
      this.hintTarget.classList.remove("usd-hint--error")
      this.submitTarget.disabled = false
    }
  }

  fmtMxn(n) {
    return `$${n.toLocaleString("es-MX", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} MXN`
  }
}
