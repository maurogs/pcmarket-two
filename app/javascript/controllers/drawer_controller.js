import { Controller } from "@hotwired/stimulus"

// Off-canvas mobile menu: open/close, Escape to close, body scroll lock.
export default class extends Controller {
  static targets = ["panel", "toggle", "overlay"]

  connect() {
    this.previouslyFocused = null
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    this.unlockScroll()
  }

  open(event) {
    if (event) event.preventDefault()

    this.previouslyFocused = document.activeElement
    this.panelTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.lockScroll()

    const focusable = this.panelTarget.querySelector("button, a[href], input")
    if (focusable) focusable.focus()
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.panelTarget.classList.contains("hidden")) return

    this.panelTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.unlockScroll()

    if (this.previouslyFocused) this.previouslyFocused.focus()
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
