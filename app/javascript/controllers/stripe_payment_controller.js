import { Controller } from "@hotwired/stimulus"

// Mounts a Stripe Payment Element and confirms the PaymentIntent created for
// the checkout. All user-facing copy comes from data values (I18n).
export default class extends Controller {
  static targets = ["element", "error", "submit"]
  static values = {
    publishableKey: String,
    clientSecret: String,
    returnUrl: String,
    locale: String,
    errorFallback: String,
    processing: String
  }

  connect() {
    if (this.hasSubmitTarget) {
      this.defaultSubmitLabel = this.submitTarget.textContent
    }

    if (!window.Stripe) {
      this.showError(this.errorFallbackValue)
      return
    }

    try {
      this.stripe = window.Stripe(this.publishableKeyValue)
      this.elements = this.stripe.elements({
        clientSecret: this.clientSecretValue,
        locale: this.localeValue
      })
      this.paymentElement = this.elements.create("payment")
      this.paymentElement.mount(this.elementTarget)
    } catch (error) {
      this.showError(this.errorFallbackValue)
    }
  }

  async submit(event) {
    event.preventDefault()

    if (!this.stripe || !this.elements) {
      this.showError(this.errorFallbackValue)
      return
    }

    this.setProcessing(true)
    this.hideError()

    const { error } = await this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: { return_url: this.returnUrlValue },
      redirect: "if_required"
    })

    if (error) {
      this.setProcessing(false)
      this.showError(error.message || this.errorFallbackValue)
      return
    }

    window.location.assign(this.returnUrlValue)
  }

  setProcessing(processing) {
    if (!this.hasSubmitTarget) return

    this.submitTarget.disabled = processing
    this.submitTarget.textContent = processing ? this.processingValue : this.defaultSubmitLabel
  }

  showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
