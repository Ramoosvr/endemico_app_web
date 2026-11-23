import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "total", "qty"]
  static values  = { basePrice: Number }

  connect() { this.recalc() }

  open(event) {
    const dialogId = event.currentTarget.dataset.dialogId
    const dialog = document.getElementById(dialogId)
    if (dialog && typeof dialog.showModal === "function") {
      dialog.showModal()
    } else if (dialog) {
      dialog.setAttribute("open", "")
    }
  }

  close() {
    const dialog = this.element
    if (typeof dialog.close === "function") dialog.close()
    else dialog.removeAttribute("open")
  }

  toggleRemove(event) {
    const id = event.target.dataset.removeId
    const hidden = this.element.querySelector(`[data-remove-hidden="${id}"]`)
    if (!hidden) return
    hidden.value = event.target.checked ? "" : id
    this.recalc()
  }

  selectSingle(event) {
    const groupId = event.target.dataset.groupId
    const choiceId = event.target.dataset.choiceId
    const hidden = this.element.querySelector(`[data-group-hidden="${groupId}"]`)
    if (hidden) hidden.value = choiceId
    this.recalc()
  }

  recalc() {
    let qty = parseInt(this.hasQtyTarget ? this.qtyTarget.value : "1", 10)
    if (isNaN(qty) || qty < 1) qty = 1

    let modifiers = 0
    const extras = this.element.querySelectorAll('input[name="extra_product_ingredient_ids[]"]:checked')
    extras.forEach(el => modifiers += parseFloat(el.dataset.extraPrice || "0"))

    const singleRadios = this.element.querySelectorAll('input[type="radio"][data-choice-id]:checked')
    singleRadios.forEach(el => modifiers += parseFloat(el.dataset.extraPrice || "0"))

    const multiChecks = this.element.querySelectorAll('input[type="checkbox"][name="option_choice_ids[]"]:checked')
    multiChecks.forEach(el => modifiers += parseFloat(el.dataset.extraPrice || "0"))

    const total = (this.basePriceValue + modifiers) * qty
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = "$" + total.toFixed(2)
    }
  }
}
