# frozen_string_literal: true

module BuybackHelper
  def buyback_condition_label(condition)
    t("buyback.conditions.#{condition}", default: condition.to_s.humanize)
  end

  def buyback_status_label(status)
    t("buyback.statuses.#{status}", default: status.to_s.humanize)
  end

  def buyback_payout_cents(price, condition)
    (price.base_offer_cents.to_i * price.condition_multiplier(condition)).round
  end

  def buyback_payout(price, condition)
    money(buyback_payout_cents(price, condition), currency: "EUR")
  end

  def buyback_timeline_state_class(state)
    case state
    when :done then "border-success/40 bg-success-soft text-success"
    when :current then "border-primary-400 bg-primary-50 text-primary-800 dark:bg-primary-900/30 dark:text-primary-100"
    else "border-border bg-surface-muted text-muted"
    end
  end

  def buyback_status_classes(status)
    case status.to_s
    when "paid" then "border-success/40 bg-success-soft text-success"
    when "rejected" then "border-danger/40 bg-danger-soft text-danger"
    when "returned" then "border-warning/40 bg-warning-soft text-warning"
    else "border-primary-300 bg-primary-50 text-primary-800 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-100"
    end
  end
end
