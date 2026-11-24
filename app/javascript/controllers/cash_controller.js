import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "change", "submit", "hint", "quick"]
  static values  = { total: Number }

  connect() {
    this.buildQuick()
    this.recalc()
  }

  buildQuick() {
    const total = this.totalValue
    const presets = this.suggestions(total)
    this.quickTarget.innerHTML = presets.map(v =>
      `<button type="button" class="cash-quick-btn" data-action="click->cash#setAmount" data-amount="${v}">$${v.toFixed(0)}</button>`
    ).join("")
  }

  suggestions(total) {
    const set = new Set()
    set.add(Math.ceil(total))
    const roundTo = (n, step) => Math.ceil(n / step) * step
    set.add(roundTo(total, 10))
    set.add(roundTo(total, 20))
    set.add(roundTo(total, 50))
    set.add(roundTo(total, 100))
    set.add(roundTo(total, 200))
    set.add(roundTo(total, 500))
    return Array.from(set).filter(v => v >= total).sort((a, b) => a - b).slice(0, 5)
  }

  setAmount(event) {
    this.inputTarget.value = event.currentTarget.dataset.amount
    this.inputTarget.focus()
    this.recalc()
  }

  recalc() {
    const paid = parseFloat(this.inputTarget.value || "0") || 0
    const change = paid - this.totalValue

    if (paid <= 0) {
      this.changeTarget.textContent = this.fmt(0)
      this.hintTarget.textContent = "Ingresa el monto recibido para calcular el cambio."
      this.hintTarget.classList.remove("cash-hint--error")
      this.submitTarget.disabled = true
      return
    }

    if (change < 0) {
      this.changeTarget.textContent = `faltan ${this.fmt(Math.abs(change))}`
      this.changeTarget.classList.add("cash-row-value--short")
      this.hintTarget.textContent = `Faltan ${this.fmt(Math.abs(change))} para cubrir el total.`
      this.hintTarget.classList.add("cash-hint--error")
      this.submitTarget.disabled = true
    } else {
      this.changeTarget.textContent = this.fmt(change)
      this.changeTarget.classList.remove("cash-row-value--short")
      this.hintTarget.textContent = change > 0
        ? `Devuelve ${this.fmt(change)} de cambio.`
        : "Monto exacto, sin cambio."
      this.hintTarget.classList.remove("cash-hint--error")
      this.submitTarget.disabled = false
    }
  }

  fmt(n) {
    return `$${n.toLocaleString("es-MX", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
  }
}
