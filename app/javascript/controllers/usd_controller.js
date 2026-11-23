import { Controller } from "@hotwired/stimulus"

// Calculates MXN equivalent and change when user types USD received.
// data-usd-total-value: order total in MXN
// data-usd-rate-value:  MXN per USD
export default class extends Controller {
  static targets = ["input", "mxnEquiv", "change", "submit", "hint"]
  static values  = { total: Number, rate: Number }

  connect() { this.recalc() }

  recalc() {
    const usd = parseFloat(this.inputTarget.value || "0") || 0
    const mxn = usd * this.rateValue
    const change = mxn - this.totalValue

    this.mxnEquivTarget.textContent = `$${mxn.toFixed(2)} MXN`

    if (usd <= 0) {
      this.changeTarget.textContent = `$0.00 MXN`
      this.hintTarget.textContent = "Ingresa los dólares recibidos para calcular el cambio automáticamente."
      this.hintTarget.classList.remove("usd-hint--error")
      this.submitTarget.disabled = true
      return
    }

    if (change < 0) {
      this.changeTarget.textContent = `faltan $${Math.abs(change).toFixed(2)}`
      this.changeTarget.classList.add("usd-row-value--short")
      this.hintTarget.textContent = `Dólares insuficientes. Pide ~$${(Math.abs(change) / this.rateValue + usd).toFixed(2)} USD.`
      this.hintTarget.classList.add("usd-hint--error")
      this.submitTarget.disabled = true
    } else {
      this.changeTarget.textContent = `$${change.toFixed(2)} MXN`
      this.changeTarget.classList.remove("usd-row-value--short")
      this.hintTarget.textContent = `Devuelve $${change.toFixed(2)} MXN de cambio.`
      this.hintTarget.classList.remove("usd-hint--error")
      this.submitTarget.disabled = false
    }
  }
}
