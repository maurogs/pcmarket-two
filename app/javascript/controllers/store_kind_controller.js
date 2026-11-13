import { Controller } from "@hotwired/stimulus"

// Reveals the legal/tax fields only for business stores. Without JavaScript the
// section stays visible, so the form remains usable.
export default class extends Controller {
  static targets = ["business"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasBusinessTarget) return

    const business = this.element.querySelector("input[name='store[kind]'][value='business']")
    this.businessTarget.classList.toggle("hidden", !business?.checked)
  }
}
