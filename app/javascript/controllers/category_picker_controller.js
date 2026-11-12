import { Controller } from "@hotwired/stimulus"

// Root → child category picker with a text filter. The root button reveals its
// child cards; the radio inputs remain normal form controls.
export default class extends Controller {
  static targets = ["search", "option", "group", "empty"]

  connect() {
    this.refreshGroups()
  }

  showChildren(event) {
    event.preventDefault()
    const rootId = event.currentTarget.dataset.categoryPickerRootParam
    const group = this.groupTargets.find((target) => target.dataset.categoryPickerGroup === rootId)
    if (!group) return

    const opening = group.classList.contains("hidden")
    group.classList.toggle("hidden", !opening)
    group.dataset.open = opening ? "true" : "false"
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = !query || (option.dataset.categorySearch || "").includes(query)
      option.classList.toggle("hidden", !matches)
      if (matches) visible += 1
    })

    if (query) {
      this.groupTargets.forEach((group) => group.classList.remove("hidden"))
    } else {
      this.refreshGroups()
    }

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible > 0)
    }
  }

  refreshGroups() {
    this.groupTargets.forEach((group) => {
      const open = group.dataset.open === "true" || group.querySelector("input:checked")
      group.classList.toggle("hidden", !open)
    })
  }
}
