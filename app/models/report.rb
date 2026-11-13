# frozen_string_literal: true

class Report < ApplicationRecord
  REPORTABLE_TYPES = %w[Listing Store Message User Review].freeze
  REASONS = %w[
    illegal_content
    counterfeit
    stolen_goods
    scam_fraud
    prohibited_item
    misleading
    harassment
    spam
    ip_infringement
    other
  ].freeze
  STATUSES = %w[open in_review actioned dismissed].freeze

  belongs_to :reporter, class_name: "User", optional: true
  belongs_to :reportable, polymorphic: true
  belongs_to :handled_by, class_name: "User", optional: true

  enum :reason, REASONS.each_with_index.to_h, scopes: false
  enum :status, STATUSES.each_with_index.to_h, scopes: false

  validates :reason, inclusion: { in: REASONS }
  validates :status, inclusion: { in: STATUSES }
  validates :details, presence: true, length: { in: 20..2000 }
  validates :reporter_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                             unless: :reporter
  validates :reportable_type, inclusion: { in: REPORTABLE_TYPES }
  validate :reporter_email_format

  scope :oldest_first, -> { order(created_at: :asc, id: :asc) }
  scope :unresolved, -> { where(status: %w[open in_review]) }

  def anonymous?
    reporter_id.nil?
  end

  def contact_email
    reporter&.email.presence || reporter_email
  end

  def resolved?
    actioned? || dismissed?
  end

  def status_label_key
    "admin.reports.statuses.#{status}"
  end

  private

  def reporter_email_format
    return if reporter_email.blank? || reporter_email.match?(URI::MailTo::EMAIL_REGEXP)

    errors.add(:reporter_email, I18n.t("reports.errors.invalid_email"))
  end
end
