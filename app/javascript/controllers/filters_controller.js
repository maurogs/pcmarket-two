import { Controller } from "@hotwired/stimulus"

// Auto-submits the listing filters inside the results Turbo frame. Checkboxes
// and selects submit immediately; text/price inputs wait 400 ms after typing.
export default class extends Controller {
  static targets = ["panel", "overlay", "openButton"]
  static values = { delay: { type: Number, default: 400 } }

  connect() {
    this.timeout = null
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    clearTimeout(this.timeout)
    document.removeEventListener("keydown", this.onKeydown)
    this.unlockScroll()
  }

  submit() {
    clearTimeout(this.timeout)
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  open(event) {
    if (event) event.preventDefault()

    this.panelTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    if (this.hasOpenButtonTarget) this.openButtonTarget.setAttribute("aria-expanded", "true")
    this.lockScroll()
    const focusable = this.panelTarget.querySelector("button, a[href], input, select")
    if (focusable) focusable.focus()
  }

  close(event) {
    if (event) event.preventDefault()

    this.panelTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
    if (this.hasOpenButtonTarget) this.openButtonTarget.setAttribute("aria-expanded", "false")
    this.unlockScroll()
    if (this.hasOpenButtonTarget) this.openButtonTarget.focus()
  }

  onKeydown(event) {
    if (event.key === "Escape" && !this.panelTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }
}
