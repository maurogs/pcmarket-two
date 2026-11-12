import { Controller } from "@hotwired/stimulus"

// Listing photo gallery: thumbnails, keyboard arrows, touch swipe and a
// full-screen lightbox. The server renders every URL so no extra request is
// needed to switch photos.
export default class extends Controller {
  static targets = [
    "main",
    "thumb",
    "counter",
    "lightbox",
    "lightboxImage",
    "lightboxCounter"
  ]
  static values = { counterTemplate: String }

  connect() {
    this.index = 0
    this.touchStartX = null
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    this.unlockScroll()
  }

  select(event) {
    event.preventDefault()
    this.update(Number(event.currentTarget.dataset.index || 0))
  }

  previous(event) {
    if (event) event.preventDefault()
    this.update(this.index - 1)
  }

  next(event) {
    if (event) event.preventDefault()
    this.update(this.index + 1)
  }

  openLightbox(event) {
    if (event) event.preventDefault()
    if (!this.hasLightboxTarget) return

    this.lightboxTarget.classList.remove("hidden")
    this.lightboxTarget.classList.add("flex")
    this.lockScroll()
    this.update(this.index)
  }

  closeLightbox(event) {
    if (event) event.preventDefault()
    if (!this.hasLightboxTarget) return

    this.lightboxTarget.classList.add("hidden")
    this.lightboxTarget.classList.remove("flex")
    this.unlockScroll()
  }

  lightboxClick(event) {
    if (event.target === this.lightboxTarget) this.closeLightbox(event)
  }

  onKeydown(event) {
    const lightboxOpen = this.hasLightboxTarget && !this.lightboxTarget.classList.contains("hidden")
    const galleryFocused = this.element.contains(document.activeElement)
    if (!lightboxOpen && !galleryFocused) return
    if (event.target.matches("input, textarea, select")) return

    if (event.key === "Escape" && lightboxOpen) {
      this.closeLightbox()
    } else if (["ArrowLeft", "ArrowRight"].includes(event.key)) {
      event.preventDefault()
      if (event.key === "ArrowLeft") this.previous() else this.next()
    }
  }

  touchStart(event) {
    this.touchStartX = event.touches[0]?.clientX ?? null
  }

  touchEnd(event) {
    if (this.touchStartX === null) return

    const endX = event.changedTouches[0]?.clientX ?? this.touchStartX
    const delta = endX - this.touchStartX
    this.touchStartX = null

    if (Math.abs(delta) < 40) return
    if (delta > 0) this.previous() else this.next()
  }

  update(index) {
    const thumbs = this.thumbTargets
    if (thumbs.length === 0) return

    this.index = (index + thumbs.length) % thumbs.length
    const thumb = thumbs[this.index]

    if (this.hasMainTarget) {
      this.mainTarget.src = thumb.dataset.large
      this.mainTarget.srcset = thumb.dataset.srcset
      this.mainTarget.alt = thumb.dataset.alt
    }

    if (this.hasLightboxImageTarget) {
      this.lightboxImageTarget.src = thumb.dataset.large
      this.lightboxImageTarget.alt = thumb.dataset.alt
    }

    const counter = this.counterTemplateValue
      .replace("%{current}", this.index + 1)
      .replace("%{total}", thumbs.length)

    if (this.hasCounterTarget) this.counterTarget.textContent = counter
    if (this.hasLightboxCounterTarget) this.lightboxCounterTarget.textContent = counter

    thumbs.forEach((element, thumbIndex) => {
      element.classList.toggle("border-primary-600", thumbIndex === this.index)
      element.classList.toggle("border-transparent", thumbIndex !== this.index)
      element.classList.toggle("hover:border-primary-300", thumbIndex !== this.index)
    })
  }

  lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }
}
