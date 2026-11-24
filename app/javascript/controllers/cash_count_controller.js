import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "subtotal", "total"]

  connect() { this.recalc() }

  recalc() {
    let total = 0
    this.inputTargets.forEach((input) => {
      const denom = parseInt(input.dataset.denom, 10)
      const qty = Math.max(0, parseInt(input.value || "0", 10) || 0)
      const sub = qty * denom
      total += sub
      const subEl = this.subtotalTargets.find((el) => parseInt(el.dataset.denom, 10) === denom)
      if (subEl) subEl.textContent = this.fmtShort(sub)
    })
    if (this.hasTotalTarget) this.totalTarget.textContent = this.fmt(total)
  }

  fmt(n) { return `$${n.toLocaleString("es-MX", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` }
  fmtShort(n) { return `$${n.toLocaleString("es-MX")}` }
}
