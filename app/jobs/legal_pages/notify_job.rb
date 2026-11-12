# frozen_string_literal: true

module LegalPages
  # Batched delivery of a published legal-page update to every active user of
  # that country, each in their own locale.
  class NotifyJob < ApplicationJob
    queue_as :default

    def perform(legal_page_id)
      page = LegalPage.find_by(id: legal_page_id)
      return if page.blank? || !page.notifiable?

      User.active.where(country_code: page.country_code).find_in_batches(batch_size: 500) do |users|
        users.each do |user|
          LegalPageMailer.notice(user, page.id).deliver_later
        end
      end
    end
  end
end
