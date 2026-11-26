import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "productId", "reason", "title", "submit"]

  open(event) {
    const btn = event.currentTarget
    const name = btn.dataset.productName
    const reason = btn.dataset.reason
    this.productIdTarget.value = btn.dataset.productId
    this.reasonTarget.value = reason

    const label = reason === "prueba" ? "prueba" : "cortesía"
    this.titleTarget.textContent = `Registrar ${name} como ${label}`
    this.submitTarget.textContent = `Registrar ${label}`

    const textarea = this.dialogTarget.querySelector("textarea[name='note']")
    if (textarea) textarea.value = ""

    if (typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
      textarea?.focus()
    }
  }

  close() {
    this.dialogTarget.close()
  }
}
