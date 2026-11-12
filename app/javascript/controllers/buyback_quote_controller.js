import { Controller } from "@hotwired/stimulus"

// Filters the model select by component type and a free-text search. The form
// remains a normal POST with a complete select when JavaScript is off.
export default class extends Controller {
  static targets = ["type", "select", "search"]

  connect() {
    this.filter()
  }

  filter() {
    const type = this.typeTargets.find((input) => input.checked)?.value
    const query = (this.searchTarget?.value || "").trim().toLowerCase()

    Array.from(this.selectTarget.options).forEach((option) => {
      if (!option.value) return

      const matchesType = !type || option.dataset.type === type
      const matchesQuery = !query || option.textContent.toLowerCase().includes(query)
      option.hidden = !(matchesType && matchesQuery)
    })

    const selected = this.selectTarget.selectedOptions[0]
    if (selected && selected.hidden) {
      const firstVisible = Array.from(this.selectTarget.options).find((option) => option.value && !option.hidden)
      this.selectTarget.value = firstVisible ? firstVisible.value : ""
    }
  }
}
