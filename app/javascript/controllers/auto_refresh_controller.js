import { Controller } from "@hotwired/stimulus"

// Reloads the page every `interval` seconds, but waits while a dialog is open
// (e.g. the refund form) so nobody loses what they were typing.
export default class extends Controller {
  static values = { interval: { type: Number, default: 10 } }

  connect() {
    this.timer = setInterval(() => this.tick(), this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    if (document.querySelector("dialog[open]")) return
    if (window.Turbo) {
      window.Turbo.visit(window.location.href, { action: "replace" })
    } else {
      window.location.reload()
    }
  }
}
