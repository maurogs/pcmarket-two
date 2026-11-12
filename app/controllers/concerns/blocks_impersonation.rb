# frozen_string_literal: true

# Impersonated sessions may browse as the target user, but must never change
# that account's credentials, delete it, download its data export or touch
# seller payout settings. The admin UI (Admin::BaseController) already returns
# 404 for impersonated sessions.
module BlocksImpersonation
  extend ActiveSupport::Concern

  included do
    before_action :block_impersonated_account_change
  end

  private

  def block_impersonated_account_change
    return unless impersonating?

    redirect_back fallback_location: root_path,
                  alert: t(impersonation_blocked_alert_key)
  end

  # Controllers can preserve a more specific message (for example the payout
  # settings notice) by overriding this hook.
  def impersonation_blocked_alert_key
    "admin.impersonation.account_blocked"
  end
end
