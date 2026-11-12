import { Controller } from "@hotwired/stimulus"

// Keeps the "select all" checkbox and the individual row checkboxes in sync for
// the seller bulk archive form. The checkboxes live outside the form element
// (via the `form` attribute), so this controller only manages their state.
export default class extends Controller {
  static targets = ["all", "item"]

  toggleAll() {
    const checked = this.allTarget.checked
    this.itemTargets.forEach((item) => { item.checked = checked })
  }

  update() {
    const total = this.itemTargets.length
    const selected = this.itemTargets.filter((item) => item.checked).length

    this.allTarget.checked = total > 0 && selected === total
    this.allTarget.indeterminate = selected > 0 && selected < total
  }
}
