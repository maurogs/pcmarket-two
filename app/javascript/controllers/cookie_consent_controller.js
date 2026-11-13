import { Controller } from "@hotwired/stimulus"

// GDPR/ePrivacy consent banner. The banner and modal are rendered by the
// server; this controller only handles the dialog, focus trap, Escape and
// activating previously inert <template data-consent="…"> blocks.
export default class extends Controller {
  static targets = ["banner", "modal"]
  static values = { consented: Boolean, categories: Object }

  connect() {
    this.modalOpen = false
    this.onKeydown = (event) => {
      if (event.key === "Escape" && this.modalOpen) this.close()
    }
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    this.previouslyFocused = document.activeElement
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    this.modalOpen = true
    document.body.style.overflow = "hidden"

    const focusable = this.focusableElements()
    ;(focusable[0] || this.modalTarget).focus()
  }

  close() {
    if (!this.modalOpen) return
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    this.modalOpen = false
    document.body.style.overflow = ""
    this.previouslyFocused?.focus?.()
  }

  backdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  trapTab(event) {
    if (event.key !== "Tab" || !this.modalOpen) return

    const focusable = this.focusableElements()
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  focusableElements() {
    return Array.from(
      this.modalTarget.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    ).filter((element) => element.offsetParent !== null)
  }
}
