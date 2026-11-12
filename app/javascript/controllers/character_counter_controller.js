import { Controller } from "@hotwired/stimulus"

// Live character count for the listing title and description fields.
export default class extends Controller {
  static targets = ["input", "output"]
  static values = { max: Number }

  connect() {
    this.update()
  }

  update() {
    if (!this.hasInputTarget || !this.hasOutputTarget) return

    const max = this.maxValue || this.inputTarget.maxLength
    const count = this.inputTarget.value.length
    this.outputTarget.textContent = `${count}/${max}`
  }
}
