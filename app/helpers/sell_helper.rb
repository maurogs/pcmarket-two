# frozen_string_literal: true

module SellHelper
  def wizard_step_label(step)
    case step.to_s
    when "photos" then t("sell.steps.photos")
    when "details" then t("sell.steps.details")
    when "price" then t("sell.steps.price")
    when "review" then t("sell.steps.review")
    else t("sell.steps.category")
    end
  end

  def wizard_step_index(step)
    Listing::WIZARD_STEPS.index(step.to_s).to_i + 1
  end

  def wizard_step_percent(step)
    (wizard_step_index(step) * 100.0 / Listing::WIZARD_STEPS.length).round
  end

  def condition_title(condition)
    t("sell.details.conditions.#{condition}.title")
  end

  def condition_description(condition)
    t("sell.details.conditions.#{condition}.description")
  end

  def listing_spec_value(listing, definition)
    (listing.specs || {}).with_indifferent_access[definition.key]
  end

  def review_field_label(item)
    item[:label] || Listing.human_attribute_name(item[:attribute])
  end
end
