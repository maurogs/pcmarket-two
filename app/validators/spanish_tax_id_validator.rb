# frozen_string_literal: true

# Validates Spanish NIF (DNI), NIE and CIF numbers, including their control
# character. Leading/trailing whitespace and hyphens are ignored.
class SpanishTaxIdValidator < ActiveModel::EachValidator
  NIF_LETTERS = "TRWAGMYFPDXBNJZSQVHLCKE"
  CIF_LETTERS = "JABCDEFGHI"
  NIF_FORMAT = /\A\d{8}[A-Z]\z/
  NIE_FORMAT = /\A[XYZ]\d{7}[A-Z]\z/
  CIF_FORMAT = /\A[ABCDEFGHJNPQRSUVW]\d{7}[0-9A-Z]\z/
  NIE_PREFIXES = { "X" => "0", "Y" => "1", "Z" => "2" }.freeze

  def validate_each(record, attribute, value)
    tax_id = normalize(value)
    return if tax_id.blank? && options[:allow_blank]

    return if valid?(tax_id)

    record.errors.add(attribute, :invalid_spanish_tax_id)
  end

  private

  def normalize(value)
    value.to_s.upcase.gsub(/[\s.-]/, "")
  end

  def valid?(tax_id)
    nif?(tax_id) || nie?(tax_id) || cif?(tax_id)
  end

  def nif?(tax_id)
    tax_id.match?(NIF_FORMAT) && tax_id[-1] == control_letter(tax_id[0, 8])
  end

  def nie?(tax_id)
    return false unless tax_id.match?(NIE_FORMAT)

    prefix = NIE_PREFIXES.fetch(tax_id[0])
    tax_id[-1] == control_letter(prefix + tax_id[1, 7])
  end

  def cif?(tax_id)
    return false unless tax_id.match?(CIF_FORMAT)

    letter = tax_id[0]
    digits = tax_id[1, 7]
    control = tax_id[-1]
    expected_digit = cif_control_digit(digits)
    expected_letter = CIF_LETTERS[expected_digit]

    case letter
    when "A", "B", "E", "H" then control == expected_digit.to_s
    when "K", "P", "Q", "S" then control == expected_letter
    else control == expected_digit.to_s || control == expected_letter
    end
  end

  def control_letter(digits)
    NIF_LETTERS[digits.to_i % 23]
  end

  def cif_control_digit(digits)
    even_sum = digits[1].to_i + digits[3].to_i + digits[5].to_i
    odd_sum = [ digits[0], digits[2], digits[4], digits[6] ].sum do |digit|
      doubled = digit.to_i * 2
      doubled > 9 ? doubled - 9 : doubled
    end

    (10 - ((even_sum + odd_sum) % 10)) % 10
  end
end
