import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["handle"]

  connect() {
    this.onDown = this.onDown.bind(this)
    this.onMove = this.onMove.bind(this)
    this.onUp = this.onUp.bind(this)
    const grip = this.hasHandleTarget ? this.handleTarget : this.element
    grip.addEventListener("pointerdown", this.onDown)
  }

  disconnect() {
    const grip = this.hasHandleTarget ? this.handleTarget : this.element
    grip.removeEventListener("pointerdown", this.onDown)
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }

  onDown(event) {
    if (event.target.closest("button, a, input, textarea, select")) return
    const rect = this.element.getBoundingClientRect()
    this.offsetX = event.clientX - rect.left
    this.offsetY = event.clientY - rect.top
    this.element.style.margin = "0"
    this.element.style.inset = "auto"
    this.element.style.transform = "none"
    this.element.style.left = rect.left + "px"
    this.element.style.top = rect.top + "px"
    this.element.classList.add("is-dragging")
    event.preventDefault()
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  }

  onMove(event) {
    const w = this.element.offsetWidth
    const h = this.element.offsetHeight
    const maxX = window.innerWidth - w
    const maxY = window.innerHeight - h
    const x = Math.max(0, Math.min(maxX, event.clientX - this.offsetX))
    const y = Math.max(0, Math.min(maxY, event.clientY - this.offsetY))
    this.element.style.left = x + "px"
    this.element.style.top = y + "px"
  }

  onUp() {
    this.element.classList.remove("is-dragging")
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }
}
