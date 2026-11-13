import { Controller } from "@hotwired/stimulus"

// Keeps the wizard progress bar in sync with the server-rendered step. Step
// links are real links, so navigation keeps working without JavaScript.
export default class extends Controller {
  static targets = ["bar", "progress"]
  static values = { step: Number, total: Number }

  connect() {
    this.render()
  }

  render() {
    const step = Math.max(1, Math.min(this.stepValue || 1, this.totalValue || 1))
    const percent = Math.round((step / this.totalValue) * 100)

    if (this.hasBarTarget) {
      this.barTarget.style.width = `${percent}%`
      this.barTarget.setAttribute("aria-valuenow", String(percent))
    }
  }
}
