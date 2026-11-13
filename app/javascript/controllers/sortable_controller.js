import { Controller } from "@hotwired/stimulus"

// Photo reordering with native HTML5 drag and drop. Up/down buttons provide the
// same action for keyboard, touch and assistive-technology users.
export default class extends Controller {
  static targets = ["list", "item", "order", "input", "preview"]
  static values = { name: { type: String, default: "listing[photo_order][]" } }

  connect() {
    this.dragged = null
    this.updateOrder()
  }

  dragStart(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.photoId || "")
    this.dragged.classList.add("opacity-50")
  }

  dragOver(event) {
    if (!this.dragged) return

    event.preventDefault()
    const target = event.target.closest("[data-sortable-target='item']")
    if (!target || target === this.dragged) return

    const rect = target.getBoundingClientRect()
    const after = event.clientY > rect.top + rect.height / 2
    target.parentNode.insertBefore(this.dragged, after ? target.nextSibling : target)
  }

  dragEnd() {
    if (this.dragged) this.dragged.classList.remove("opacity-50")
    this.dragged = null
    this.updateOrder()
  }

  drop(event) {
    event.preventDefault()
    this.dragEnd()
  }

  moveUp(event) {
    event.preventDefault()
    const item = this.itemFor(event)
    if (item?.previousElementSibling) {
      item.parentNode.insertBefore(item, item.previousElementSibling)
      this.updateOrder()
      this.focusButton(item, "up")
    }
  }

  moveDown(event) {
    event.preventDefault()
    const item = this.itemFor(event)
    if (item?.nextElementSibling) {
      item.parentNode.insertBefore(item.nextElementSibling, item)
      this.updateOrder()
      this.focusButton(item, "down")
    }
  }

  updateOrder() {
    if (!this.hasOrderTarget || !this.hasItemTarget) return

    const ids = this.itemTargets
      .map((item) => item.dataset.sortableId || item.dataset.photoId)
      .filter((id) => id)

    this.orderTarget.innerHTML = ids
      .map((id) => `<input type="hidden" name="${this.escape(this.nameValue)}" value="${this.escape(id)}">`)
      .join("")
  }

  preview(event) {
    if (!this.hasPreviewTarget) return

    this.previewTarget.innerHTML = ""
    Array.from(event.target.files || []).forEach((file) => {
      if (!file.type.startsWith("image/")) return

      const image = document.createElement("img")
      image.src = URL.createObjectURL(file)
      image.alt = ""
      image.className = "aspect-square h-full w-full rounded-xl border border-border object-cover"
      image.addEventListener("load", () => URL.revokeObjectURL(image.src), { once: true })
      this.previewTarget.appendChild(image)
    })
  }

  itemFor(event) {
    return event.target.closest("[data-sortable-target='item']")
  }

  focusButton(item, direction) {
    const selector = direction === "up" ? "[data-action~='sortable#moveUp']" : "[data-action~='sortable#moveDown']"
    item.querySelector(selector)?.focus()
  }

  escape(value) {
    return String(value).replace(/[&<>"']/g, (character) => {
      const entities = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }
      return entities[character]
    })
  }
}
