import { Controller } from "@hotwired/stimulus"

// Keeps the colour-token preview in sync with the select without a page reload.
export default class extends Controller {
  static targets = ["select", "preview"]
  static values = { styles: Object }

  connect() {
    this.update()
  }

  update() {
    if (!this.hasSelectTarget || !this.hasPreviewTarget) return

    const style = this.stylesValue[this.selectTarget.value] || ""
    this.previewTarget.className = `inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-semibold ${style}`
    this.previewTarget.textContent = this.selectTarget.selectedOptions[0]?.text || ""
  }
}
