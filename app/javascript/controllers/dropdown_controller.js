import { Controller } from "@hotwired/stimulus"

// Generic dropdown menu: click outside and Escape close it, arrow keys move
// between [role="menuitem"] items and focus returns to the trigger on close.
export default class extends Controller {
  static targets = ["menu", "trigger"]

  connect() {
    this.clickOutside = this.clickOutside.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
  }

  disconnect() {
    this.removeDocumentListeners()
  }

  toggle(event) {
    if (event) event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.clickOutside)
    document.addEventListener("keydown", this.onKeydown)

    const firstItem = this.items[0]
    if (firstItem) firstItem.focus()
  }

  close({ restoreFocus = false } = {}) {
    if (!this.isOpen) return

    this.menuTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.removeDocumentListeners()
    if (restoreFocus) this.triggerTarget.focus()
  }

  triggerKeydown(event) {
    if (!["ArrowDown", "ArrowUp"].includes(event.key)) return

    event.preventDefault()
    if (!this.isOpen) this.open()

    const items = this.items
    if (items.length === 0) return

    const target = event.key === "ArrowUp" ? items[items.length - 1] : items[0]
    target.focus()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  onKeydown(event) {
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

  get items() {
    return Array.from(this.menuTarget.querySelectorAll("[role='menuitem']"))
  }

  get isOpen() {
    return !this.menuTarget.classList.contains("hidden")
  }

  removeDocumentListeners() {
    document.removeEventListener("click", this.clickOutside)
    document.removeEventListener("keydown", this.onKeydown)
  }
}
