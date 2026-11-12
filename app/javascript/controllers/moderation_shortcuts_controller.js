import { Controller } from "@hotwired/stimulus"

// Moderation keyboard shortcuts: A approves, R focuses the rejection reasons,
// J/K move to the next/previous pending listing. Shortcuts never fire while
// the user is typing.
export default class extends Controller {
  static targets = ["approve", "reject", "next", "previous"]

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (this.isEditing(event.target)) return

    switch (event.key.toLowerCase()) {
      case "a":
        if (!this.hasApproveTarget) return
        event.preventDefault()
        this.approveTarget.click()
        break
      case "r":
        if (!this.hasRejectTarget) return
        event.preventDefault()
        this.rejectTarget.focus()
        break
      case "j":
        if (!this.hasNextTarget) return
        event.preventDefault()
        this.nextTarget.click()
        break
      case "k":
        if (!this.hasPreviousTarget) return
        event.preventDefault()
        this.previousTarget.click()
        break
    }
  }

  isEditing(target) {
    if (!(target instanceof HTMLElement)) return false

    const tag = target.tagName.toLowerCase()
    return tag === "input" || tag === "textarea" || tag === "select" || target.isContentEditable
  }
}
