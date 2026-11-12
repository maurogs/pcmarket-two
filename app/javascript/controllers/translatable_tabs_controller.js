import { Controller } from "@hotwired/stimulus"

// Tabbed six-locale inputs for jsonb-translated fields. The ES tab is active by
// default; the coloured dot on each tab reflects whether the value is present.
export default class extends Controller {
  static targets = ["tab", "panel", "dot", "field"]

  select(event) {
    event.preventDefault()
    this.activate(event.currentTarget.dataset.locale)
  }

  navigate(event) {
    const keys = ["ArrowLeft", "ArrowRight", "Home", "End"]
    if (!keys.includes(event.key)) return

    event.preventDefault()
    const tabs = this.tabTargets
    const current = tabs.indexOf(event.currentTarget)
    let next = current

    if (event.key === "ArrowLeft") next = (current - 1 + tabs.length) % tabs.length
    if (event.key === "ArrowRight") next = (current + 1) % tabs.length
    if (event.key === "Home") next = 0
    if (event.key === "End") next = tabs.length - 1

    tabs[next].focus()
    this.activate(tabs[next].dataset.locale)
  }

  refresh(event) {
    this.updateDot(event.currentTarget.dataset.locale)
  }

  activate(locale) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.locale === locale
      tab.setAttribute("aria-selected", active ? "true" : "false")
      tab.tabIndex = active ? 0 : -1
      tab.classList.toggle("bg-surface", active)
      tab.classList.toggle("text-content", active)
      tab.classList.toggle("shadow-sm", active)
      tab.classList.toggle("text-muted", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.locale !== locale)
    })
  }

  updateDot(locale) {
    const field = this.fieldTargets.find((input) => input.dataset.locale === locale)
    const dot = this.dotTargets.find((element) => element.dataset.locale === locale)
    if (!field || !dot) return

    const present = field.value.trim().length > 0
    dot.classList.toggle("bg-success", present)
    dot.classList.toggle("bg-danger", !present)
  }
}
