# frozen_string_literal: true

class LegalPage < ApplicationRecord
  KINDS = %w[
    terms privacy cookies legal_notice returns seller_terms buyer_protection
    dsa_transparency prohibited_items fees accessibility
  ].freeze

  # Kinds that change the contract or data processing materially and therefore
  # can trigger a user notification once published.
  NOTIFIABLE_KINDS = %w[terms privacy].freeze

  belongs_to :country, foreign_key: :country_code, primary_key: :code,
                       inverse_of: :legal_pages

  has_rich_text :body

  enum :kind, KINDS.each_with_index.to_h { |kind, index| [ kind, index ] },
       scopes: false
  enum :status, { draft: 0, published: 1 }, scopes: false

  validates :country_code, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :title, presence: true
  validates :version, presence: true,
                      uniqueness: { scope: %i[country_code locale kind] }
  validates :kind, inclusion: { in: KINDS }
  validate :effective_after_publication

  scope :for_kind, ->(kind) { where(kind: kind) }
  scope :published, -> { where(status: :published) }
  scope :live, -> { published.where("effective_at IS NULL OR effective_at <= ?", Time.current) }
  scope :newest_first, -> { order(effective_at: :desc, published_at: :desc, id: :desc) }

  # Public lookup with the agreed fallback chain: requested locale, the
  # country's default locale, then Spanish. Only published rows that are
  # already effective are eligible.
  def self.current(country:, locale:, kind:)
    country_code = country.respond_to?(:code) ? country.code : country.to_s.upcase
    country_record = Country.find_by(code: country_code)
    candidates = [ locale, country_record&.default_locale, I18n.default_locale ]
                 .compact.map(&:to_s).uniq

    candidates.each do |candidate|
      page = live.where(country_code: country_code, locale: candidate, kind: kind)
                 .newest_first.first
      return page if page
    end

    nil
  end

  # Most recent row (draft or published) for the same country, locale and kind.
  def self.latest_for(page)
    where(country_code: page.country_code, locale: page.locale, kind: page.kind)
      .order(created_at: :desc, id: :desc).first
  end

  def notifiable?
    NOTIFIABLE_KINDS.include?(kind.to_s)
  end

  def publish!(effective_at: Time.current)
    update!(status: :published, published_at: (published_at || Time.current),
            effective_at: effective_at)
  end

  def notify_users!
    return false unless notifiable? && published?

    update!(notified_at: Time.current)
    LegalPages::NotifyJob.perform_later(id)
    true
  end

  def plain_body
    body.to_plain_text
  end

  private

  def effective_after_publication
    return if effective_at.blank? || published_at.blank?
    return if effective_at.to_date >= published_at.to_date

    errors.add(:effective_at, I18n.t("legal_pages.errors.effective_before_publication"))
  end
end
