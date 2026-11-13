import { Controller } from "@hotwired/stimulus"

// Toggles the `dark` class on <html> and remembers the choice.
// The initial class is applied by an inline script in <head> to avoid a flash.
export default class extends Controller {
  connect() {
    this.sync()
  }

  toggle() {
    const root = document.documentElement
    const dark = !root.classList.contains("dark")

    root.classList.toggle("dark", dark)

    try {
      localStorage.setItem("theme", dark ? "dark" : "light")
    } catch (error) {
      // Storage can be unavailable (private mode, blocked cookies): keep the in-page theme.
    }

    this.sync()
  }

  sync() {
    const dark = document.documentElement.classList.contains("dark")
    this.element.setAttribute("aria-pressed", dark.toString())
  }
}
