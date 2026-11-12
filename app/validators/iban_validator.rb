# frozen_string_literal: true

# Validates an IBAN's shape and ISO 13616 mod-97 checksum. Spaces and hyphens
# are tolerated because people copy IBANs in printed groups.
class IbanValidator < ActiveModel::EachValidator
  FORMAT = /\A[A-Z]{2}\d{2}[A-Z0-9]{11,30}\z/

  def validate_each(record, attribute, value)
    normalised = self.class.normalise(value)
    if normalised.blank?
      record.errors.add(attribute, :blank)
    elsif !self.class.valid?(normalised)
      record.errors.add(attribute, :invalid_iban)
    end
  end

  def self.normalise(value)
    value.to_s.gsub(/[\s-]/, "").upcase
  end

  def self.valid?(value)
    iban = normalise(value)
    return false unless FORMAT.match?(iban)

    rearranged = iban[4..] + iban[0, 4]
    numeric = rearranged.chars.map { |char| char.match?(/\d/) ? char : (char.ord - 55).to_s }.join
    numeric.to_i % 97 == 1
  end

  def self.last4(value)
    normalise(value)[-4..]
  end
end
