import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for the PC Finder quiz. Without JavaScript every
// step is visible and the form submits as one ordinary GET request.
export default class extends Controller {
  static targets = ["step", "progress", "progressItem", "next", "back", "submit", "game"]
  static values = { progressTemplate: String }

  connect() {
    if (this.stepTargets.length === 0) return

    this.index = 0
    this.render()
    this.enforceGameLimit()
  }

  next() {
    if (!this.validate()) return

    this.index = Math.min(this.index + 1, this.stepTargets.length - 1)
    this.render()
  }

  back() {
    this.index = Math.max(this.index - 1, 0)
    this.render()
  }

  enforceGameLimit() {
    const checked = this.gameTargets.filter((input) => input.checked)
    const atLimit = checked.length >= 3
    this.gameTargets.forEach((input) => {
      input.disabled = atLimit && !input.checked
    })
  }

  validate() {
    if (this.index === 0) {
      const checked = this.gameTargets.filter((input) => input.checked)
      if (checked.length > 3) {
        this.gameTargets.forEach((input, index) => {
          if (index >= 3) input.checked = false
        })
      }
    }
    return true
  }

  render() {
    const last = this.stepTargets.length - 1
    this.stepTargets.forEach((step, index) => {
      step.hidden = index !== this.index
    })

    this.backTarget.hidden = this.index === 0
    this.nextTarget.hidden = this.index === last
    this.submitTarget.hidden = this.index !== last

    if (this.hasProgressTarget && this.progressTemplateValue) {
      this.progressTarget.textContent = this.progressTemplateValue.replace("%{current}", `${this.index + 1}`)
    }

    this.progressItemTargets.forEach((item, index) => {
      item.classList.toggle("border-primary-500", index === this.index)
      item.classList.toggle("text-content", index === this.index)
      item.classList.toggle("bg-primary-50", index === this.index)
      item.classList.toggle("dark:bg-primary-900/30", index === this.index)
    })
  }
}
