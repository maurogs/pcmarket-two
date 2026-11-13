# frozen_string_literal: true

module Messages
  # Detects contact details and off-platform payment requests. It never blocks
  # a message: the UI shows a warning to the recipient instead.
  class SafetyScanner
    REASONS = %w[phone email iban external_payment].freeze

    EMAIL_PATTERN = /\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b/i
    IBAN_PATTERN = /(?:ES|FR|DE|IT|PT|GB|NL|BE|AT|IE|LU|CH|SE|DK|FI|NO|PL|CZ|RO|GR|HU|BG|HR|SK|SI|EE|LV|LT|MT|CY)\d{2}[A-Z0-9]{10,30}/i
    PHONE_CANDIDATE = /\+?\d[\d\s().\-]{7,}\d/

    EXTERNAL_PAYMENT_TERMS = [
      "bizum",
      "transferencia",
      "transferencia bancaria",
      "bank transfer",
      "virement",
      "virement bancaire",
      "überweisung",
      "ueberweisung",
      "bonifico",
      "bonifico bancario",
      "transferência",
      "transferencia bancária",
      "paypal friends",
      "paypal.me",
      "friends and family",
      "amigos y familiares",
      "amis et famille",
      "familie und freunde",
      "amici e familiari",
      "amigos e familiares",
      "western union",
      "moneygram",
      "cash app",
      "venmo",
      "revolut",
      "payoneer",
      "bitcoin",
      "criptomoneda",
      "crypto",
      "pago fuera de la plataforma",
      "fuera de la plataforma",
      "off platform",
      "hors plateforme",
      "außerhalb der plattform",
      "fuori piattaforma",
      "fora da plataforma",
      "contra reembolso",
      "cash on delivery"
    ].freeze

    def self.call(body)
      new(body).call
    end

    def initialize(body)
      @body = body.to_s
    end

    def call
      reasons = []
      reasons << "email" if body.match?(EMAIL_PATTERN)
      reasons << "iban" if body.gsub(/\s+/, "").match?(IBAN_PATTERN)
      reasons << "phone" if phone_number?
      reasons << "external_payment" if external_payment?

      reasons
    end

    def flagged?
      call.any?
    end

    private

    attr_reader :body

    def phone_number?
      body.scan(PHONE_CANDIDATE).any? do |candidate|
        candidate.gsub(/\D/, "").length.between?(9, 15)
      end
    end

    def external_payment?
      normalized = body.downcase
      EXTERNAL_PAYMENT_TERMS.any? { |term| normalized.include?(term) }
    end
  end
end
