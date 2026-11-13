import { Controller } from "@hotwired/stimulus"

// Accessible autoplaying carousel: pauses on hover/focus, supports arrows,
// dots, swipe and respects prefers-reduced-motion.
export default class extends Controller {
  static targets = ["track", "slide", "dot"]
  static values = { interval: { type: Number, default: 6000 } }

  connect() {
    this.index = 0
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.touchStartX = null

    this.onMouseEnter = () => this.pause()
    this.onMouseLeave = () => this.start()
    this.onFocusIn = () => this.pause()
    this.onFocusOut = (event) => {
      if (!this.element.contains(event.relatedTarget)) this.start()
    }
    this.onPointerDown = (event) => { this.touchStartX = event.clientX }
    this.onPointerUp = (event) => {
      if (this.touchStartX === null) return
      const delta = event.clientX - this.touchStartX
      this.touchStartX = null
      if (Math.abs(delta) < 45) return
      delta < 0 ? this.next() : this.previous()
    }

    this.element.addEventListener("mouseenter", this.onMouseEnter)
    this.element.addEventListener("mouseleave", this.onMouseLeave)
    this.element.addEventListener("focusin", this.onFocusIn)
    this.element.addEventListener("focusout", this.onFocusOut)
    this.trackTarget.addEventListener("pointerdown", this.onPointerDown)
    this.trackTarget.addEventListener("pointerup", this.onPointerUp)

    this.show()
    this.start()
  }

  disconnect() {
    this.pause()
    this.element.removeEventListener("mouseenter", this.onMouseEnter)
    this.element.removeEventListener("mouseleave", this.onMouseLeave)
    this.element.removeEventListener("focusin", this.onFocusIn)
    this.element.removeEventListener("focusout", this.onFocusOut)
    this.trackTarget.removeEventListener("pointerdown", this.onPointerDown)
    this.trackTarget.removeEventListener("pointerup", this.onPointerUp)
  }

  start() {
    this.pause()
    if (this.reducedMotion || this.slideTargets.length < 2) return

    this.timer = setInterval(() => this.next(), Math.max(this.intervalValue, 3000))
  }

  pause() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  next() {
    this.moveTo(this.index + 1)
  }

  previous() {
    this.moveTo(this.index - 1)
  }

  goTo(event) {
    const index = Number(event.params.index ?? event.currentTarget.dataset.index)
    if (Number.isNaN(index)) return
    this.moveTo(index)
  }

  moveTo(index) {
    const total = this.slideTargets.length
    if (total === 0) return
    this.index = (index + total) % total
    this.show()
  }

  show() {
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`

    this.slideTargets.forEach((slide, index) => {
      const active = index === this.index
      slide.setAttribute("aria-hidden", active ? "false" : "true")
      slide.toggleAttribute("inert", !active)
      slide.querySelectorAll("a, button").forEach((element) => {
        if (element.getAttribute("aria-hidden") === "true") return
        element.tabIndex = active ? 0 : -1
      })
    })

    this.dotTargets.forEach((dot, index) => {
      const active = index === this.index
      dot.setAttribute("aria-selected", active ? "true" : "false")
      dot.classList.toggle("w-7", active)
      dot.classList.toggle("bg-white", active)
      dot.classList.toggle("w-2.5", !active)
      dot.classList.toggle("bg-white/40", !active)
    })
  }
}
