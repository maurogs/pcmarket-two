import { Controller } from "@hotwired/stimulus"

// Aligns message bubbles to the current user, reveals safety warnings only to
// the recipient, shows read receipts on own messages and keeps the thread
// scrolled to the latest message.
export default class extends Controller {
  static values = { currentUserId: Number }
  static targets = ["messages", "input"]

  connect() {
    this.enhance()
    this.scrollToBottom()
    this.observer = new MutationObserver(() => {
      this.enhance()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  submitOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey) return

    event.preventDefault()
    event.target.form?.requestSubmit()
  }

  enhance() {
    this.element.querySelectorAll("[data-chat-message]").forEach((message) => {
      const own = Number(message.dataset.chatSenderId) === this.currentUserIdValue
      message.classList.toggle("justify-end", own)
      const bubble = message.querySelector("[data-chat-bubble]")
      if (!bubble) return

      bubble.classList.toggle("bg-primary-600", own)
      bubble.classList.toggle("border-primary-600", own)
      bubble.classList.toggle("text-white", own)
      bubble.classList.toggle("bg-surface-muted", !own)
      bubble.classList.toggle("text-content", !own)
    })

    this.element.querySelectorAll("[data-chat-safety]").forEach((banner) => {
      banner.classList.toggle("hidden", Number(banner.dataset.chatSenderId) === this.currentUserIdValue)
    })

    this.element.querySelectorAll("[data-chat-read-receipt]").forEach((receipt) => {
      const message = receipt.closest("[data-chat-message]")
      receipt.classList.toggle("hidden", Number(message?.dataset.chatSenderId) !== this.currentUserIdValue)
    })
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
