import { Controller } from "@hotwired/stimulus"

// Auto-dismisses flash messages after `delay` milliseconds.
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    this.element.classList.add("opacity-0", "transition", "duration-300")

    this.removalTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
