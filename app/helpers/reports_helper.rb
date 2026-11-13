# frozen_string_literal: true

module ReportsHelper
  def reportable_label(reportable)
    return t("admin.reports.deleted_item") if reportable.blank?

    case reportable
    when Listing then reportable.title
    when Store then reportable.name
    when Message then truncate(reportable.body, length: 90)
    when User then reportable.display_name
    when Review then t("reports.review_preview", rating: reportable.rating)
    else reportable.class.model_name.human
    end
  end

  def report_reason_label(reason)
    t("reports.reasons.#{reason}")
  end

  def report_status_label(status)
    t("admin.reports.statuses.#{status}")
  end

  def report_type_label(type)
    t("admin.reports.types.#{type.to_s.underscore}")
  end
end
