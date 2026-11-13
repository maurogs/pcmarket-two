import { Controller } from "@hotwired/stimulus"

// Desktop category mega-menu. Hovering opens after a short intent delay, while
// click, Enter, Space and ArrowDown work for keyboard/touch users. Escape and
// clicks outside close the panel and return focus to the trigger.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.openTimer = null
    this.closeTimer = null
    this.clickOutside = this.clickOutside.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
  }

  disconnect() {
    this.clearTimers()
    this.removeDocumentListeners()
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  intentOpen() {
    clearTimeout(this.closeTimer)
    clearTimeout(this.openTimer)
    this.openTimer = setTimeout(() => this.open(), 120)
  }

  intentClose() {
    clearTimeout(this.openTimer)
    clearTimeout(this.closeTimer)
    this.closeTimer = setTimeout(() => this.close(), 180)
  }

  open() {
    this.clearTimers()
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.clickOutside)
    document.addEventListener("keydown", this.onKeydown)
  }

  close({ restoreFocus = false } = {}) {
    if (!this.isOpen) return

    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.removeDocumentListeners()
    if (restoreFocus) this.triggerTarget.focus()
  }

  triggerKeydown(event) {
    if (!["ArrowDown", "Enter", " ", "Escape"].includes(event.key)) return

    if (event.key === "Escape") {
      this.close({ restoreFocus: true })
      return
    }

    event.preventDefault()
    if (!this.isOpen) this.open()

    const items = this.items
    if (items.length > 0) items[0].focus()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  onKeydown(event) {
    if (!this.isOpen) return

    if (event.key === "Escape") {
      this.close({ restoreFocus: true })
      return
    }

    if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return

    event.preventDefault()
    const items = this.items
    if (items.length === 0) return

    const index = items.indexOf(document.activeElement)
    let nextIndex = 0

    if (event.key === "ArrowDown") nextIndex = index < items.length - 1 ? index + 1 : 0
    if (event.key === "ArrowUp") nextIndex = index > 0 ? index - 1 : items.length - 1
    if (event.key === "End") nextIndex = items.length - 1

    items[nextIndex].focus()
  }

  get isOpen() {
    return !this.panelTarget.hidden
  }

  get items() {
    return Array.from(this.panelTarget.querySelectorAll("a[href], button"))
  }

  clearTimers() {
    clearTimeout(this.openTimer)
    clearTimeout(this.closeTimer)
  }

  removeDocumentListeners() {
    document.removeEventListener("click", this.clickOutside)
    document.removeEventListener("keydown", this.onKeydown)
  }
}
