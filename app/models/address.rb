# frozen_string_literal: true

class Address < ApplicationRecord
  # ISO 3166-2:ES province code -> first two digits of the postal code.
  PROVINCE_PREFIXES = {
    "A" => "03", "AB" => "02", "AL" => "04", "AV" => "05", "B" => "08",
    "BA" => "06", "BI" => "48", "BU" => "09", "C" => "15", "CA" => "11",
    "CC" => "10", "CE" => "51", "CO" => "14", "CR" => "13", "CS" => "12",
    "CU" => "16", "GC" => "35", "GI" => "17", "GR" => "18", "GU" => "19",
    "H" => "21", "HU" => "22", "J" => "23", "L" => "25", "LE" => "24",
    "LO" => "26", "LU" => "27", "M" => "28", "MA" => "29", "ML" => "52",
    "MU" => "30", "NA" => "31", "O" => "33", "OR" => "32", "P" => "34",
    "PM" => "07", "PO" => "36", "S" => "39", "SA" => "37", "SE" => "41",
    "SG" => "40", "SO" => "42", "SS" => "20", "T" => "43", "TE" => "44",
    "TF" => "38", "TO" => "45", "V" => "46", "VA" => "47", "VI" => "01",
    "Z" => "50", "ZA" => "49"
  }.freeze

  belongs_to :user, optional: true
  belongs_to :region, optional: true

  normalizes :country_code, with: ->(code) { code.to_s.strip.upcase }
  normalizes :postal_code, with: ->(postal_code) { postal_code.to_s.strip }

  validates :full_name, :line1, :city, :postal_code, :phone, presence: true
  validates :country_code, presence: true, format: { with: /\A[A-Z]{2}\z/ }
  validate :postal_code_matches_province
  validate :region_belongs_to_country

  before_save :clear_other_defaults, if: :default?

  scope :default_first, -> { order(default: :desc, created_at: :asc) }

  def province_name
    region&.name
  end

  def to_snapshot
    {
      "full_name" => full_name,
      "line1" => line1,
      "line2" => line2,
      "city" => city,
      "province" => province_name,
      "region_code" => region&.code,
      "postal_code" => postal_code,
      "country_code" => country_code,
      "phone" => phone
    }
  end

  private

  def spain?
    country_code == "ES"
  end

  def postal_code_matches_province
    return if postal_code.blank?

    unless spain?
      return
    end

    unless postal_code.match?(/\A\d{5}\z/)
      errors.add(:postal_code, I18n.t("addresses.errors.postal_code_format"))
      return
    end

    if region.blank?
      errors.add(:region, I18n.t("addresses.errors.province_required"))
      return
    end

    prefix = PROVINCE_PREFIXES[region.code]
    return if prefix.blank? || postal_code.start_with?(prefix)

    errors.add(:postal_code, I18n.t("addresses.errors.postal_code_province"))
  end

  def region_belongs_to_country
    return if region.blank? || country_code.blank?
    return if region.country_code == country_code

    errors.add(:region, I18n.t("addresses.errors.region_country_mismatch"))
  end

  def clear_other_defaults
    self.class.where(user_id: user_id).where.not(id: id).update_all(default: false)
  end
end
