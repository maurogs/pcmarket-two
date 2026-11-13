# frozen_string_literal: true

module ConversationsHelper
  include MoneyHelper

  def message_text(message)
    return message.body unless message.event?

    params = (message.metadata || {}).to_h.symbolize_keys
    if params.key?(:amount_cents)
      params[:amount] = money(params.delete(:amount_cents), currency: params[:currency])
    end
    t(message.body, **params)
  rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument
    message.body
  end

  def conversation_counterparty(conversation, user)
    conversation.other_party_for(user)
  end

  def conversation_avatar_tag(user, size: "h-10 w-10")
    if user.avatar.attached?
      image_tag url_for(user.avatar.variant(resize_to_limit: [ 96, 96 ], format: :webp)),
                alt: user.display_name,
                class: "#{size} shrink-0 rounded-full object-cover"
    else
      content_tag(:span,
                  user.display_name.first(2).upcase,
                  class: "#{size} flex shrink-0 items-center justify-center rounded-full bg-primary-100 text-xs font-bold text-primary-700 dark:bg-primary-900/40 dark:text-primary-200")
    end
  end

  def conversation_last_message(conversation)
    messages = conversation.messages
    message = if messages.loaded?
      messages.reject(&:hidden_at).max_by { |candidate| [ candidate.created_at, candidate.id ] }
    else
      messages.visible.last
    end
    return t("conversations.index.no_messages") if message.blank?

    message.event? ? message_text(message) : message.body
  end

  def conversation_unread_badge(conversation, user)
    count = conversation.unread_count_for(user)
    return if count.zero?

    content_tag(:span,
                count,
                class: "inline-flex min-w-5 items-center justify-center rounded-full bg-accent px-1.5 py-0.5 text-[11px] font-bold leading-none text-on-accent")
  end

  def message_report_path(message)
    new_report_path(reportable_type: "Message", reportable_id: message.id)
  end
end
