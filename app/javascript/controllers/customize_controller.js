import { Controller } from "@hotwired/stimulus"

const MAX_COUNTER = 10

export default class extends Controller {
  static targets = ["form", "total", "qty", "error"]
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

  // Optional single-choice groups (e.g. Latte "Sabor"): tapping the chosen
  // chip again clears it.
  toggleOptional(event) {
    const radio = event.target
    if (radio.dataset.wasChecked === "true") {
      radio.checked = false
      radio.dataset.wasChecked = "false"
      const hidden = this.element.querySelector(`[data-group-hidden="${radio.dataset.groupId}"]`)
      if (hidden) hidden.value = ""
      this.recalc()
      return
    }
    this.element
      .querySelectorAll(`input[type="radio"][data-group-id="${radio.dataset.groupId}"]`)
      .forEach(el => { el.dataset.wasChecked = "false" })
    radio.dataset.wasChecked = "true"
  }

  increment(event) { this.step(event, 1) }
  decrement(event) { this.step(event, -1) }

  step(event, delta) {
    const box = event.currentTarget.closest("[data-counter-group]")
    const input = box.querySelector("[data-counter-qty]")
    let n = parseInt(input.value, 10) || 0
    n = Math.min(MAX_COUNTER, Math.max(0, n + delta))
    input.value = n
    box.classList.toggle("is-active", n > 0)

    const flavors = box.querySelector(".cmz-counter-flavors")
    if (flavors) {
      flavors.hidden = n === 0
      if (n === 0) flavors.querySelectorAll("input").forEach(el => { el.checked = false })
    }
    this.hideError()
    this.recalc()
  }

  pickFlavor() { this.hideError() }

  validate(event) {
    const missing = Array.from(this.element.querySelectorAll("[data-counter-group]")).find(box => {
      const n = parseInt(box.querySelector("[data-counter-qty]").value, 10) || 0
      const flavors = box.querySelector(".cmz-counter-flavors")
      return n > 0 && flavors && !flavors.querySelector("input:checked")
    })
    if (!missing) return

    event.preventDefault()
    const name = missing.querySelector(".cmz-counter-name")?.textContent?.trim() || "el extra"
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = `Elige el sabor de ${name}.`
      this.errorTarget.hidden = false
    }
    missing.scrollIntoView({ block: "center", behavior: "smooth" })
  }

  hideError() {
    if (this.hasErrorTarget) this.errorTarget.hidden = true
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

    this.element.querySelectorAll("[data-counter-group]").forEach(box => {
      const n = parseInt(box.querySelector("[data-counter-qty]").value, 10) || 0
      modifiers += n * parseFloat(box.dataset.extraPrice || "0")
    })

    const total = (this.basePriceValue + modifiers) * qty
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = "$" + total.toFixed(2)
    }
  }
}
