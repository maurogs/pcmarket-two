import { Controller } from "@hotwired/stimulus"

// Activates consent-gated third-party tags. Each inert <template> declares its
// category with data-consent="analytics" (or "marketing"). Until the matching
// category is accepted the template stays in the DOM and nothing runs.
export default class extends Controller {
  static values = { categories: Object }

  connect() {
    this.activate()
  }

  activate() {
    document.querySelectorAll("template[data-consent]").forEach((template) => {
      const category = template.dataset.consent
      if (!this.categoriesValue?.[category]) return

      template.replaceWith(template.content.cloneNode(true))
    })
  }
}
