import { Controller } from "@hotwired/stimulus"

// Horizontal scroll-snap rail with desktop arrow buttons.
export default class extends Controller {
  static targets = ["track", "previous", "next"]

  connect() {
    this.updateButtons()
    this.trackTarget.addEventListener("scroll", this.onScroll = () => this.updateButtons(), { passive: true })
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
  }

  previous() {
    this.scroll(-1)
  }

  next() {
    this.scroll(1)
  }

  scroll(direction) {
    const behavior = window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
    this.trackTarget.scrollBy({ left: direction * this.trackTarget.clientWidth * 0.85, behavior })
  }

  updateButtons() {
    if (!this.hasPreviousTarget || !this.hasNextTarget) return

    const maxScroll = this.trackTarget.scrollWidth - this.trackTarget.clientWidth
    this.previousTarget.disabled = this.trackTarget.scrollLeft <= 2
    this.nextTarget.disabled = this.trackTarget.scrollLeft >= maxScroll - 2
    this.previousTarget.classList.toggle("opacity-40", this.previousTarget.disabled)
    this.nextTarget.classList.toggle("opacity-40", this.nextTarget.disabled)
  }
}
