import { Controller } from "@hotwired/stimulus"

// Asks "¿A nombre de quién?" when the first product of a new order is tapped,
// then continues with that product. Later products don't ask again.
export default class extends Controller {
  static targets = ["dialog", "product"]
  static values  = { needed: Boolean, open: Number }

  connect() {
    this.intercept = this.intercept.bind(this)
    if (this.neededValue) this.element.addEventListener("click", this.intercept, true)

    // Coming back from the name step: open the product that was tapped.
    if (this.openValue) {
      const dialog = document.getElementById(`customize-${this.openValue}`)
      if (dialog && typeof dialog.showModal === "function") dialog.showModal()
      const url = new URL(window.location.href)
      url.searchParams.delete("abrir")
      window.history.replaceState(window.history.state, "", url)
    }
  }

  disconnect() {
    this.element.removeEventListener("click", this.intercept, true)
  }

  intercept(event) {
    const card = event.target.closest(".pcard--btn")
    if (!card || this.dialogTarget.contains(card)) return

    event.preventDefault()
    event.stopPropagation()
    const form = card.closest("form")
    const productId = card.dataset.productId || form?.dataset.productId
    this.productTarget.value = productId || ""
    this.show()
  }

  change() {
    this.productTarget.value = ""
    this.show()
  }

  cancel() {
    this.dialogTarget.close()
  }

  show() {
    const dialog = this.dialogTarget
    if (typeof dialog.showModal === "function") dialog.showModal()
    else dialog.setAttribute("open", "")
    dialog.querySelector("input[type=text]")?.focus()
  }
}
