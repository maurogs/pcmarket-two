# frozen_string_literal: true

module Account
  class DataExportsController < ApplicationController
    before_action :authenticate_user!, only: :create

    def create
      authorize current_user, :export?, policy_class: AccountPolicy
      Accounts::DataExportJob.perform_later(current_user.id)
      redirect_to account_privacy_path, notice: t("account.privacy.flash.queued")
    end

    def show
      user_id = Accounts::ExportToken.verify(params[:token])

      if user_id.blank?
        redirect_to root_path, alert: t("account.privacy.flash.invalid_link")
        return
      end

      user = User.find_by(id: user_id)
      unless user&.data_export&.attached?
        redirect_to root_path, alert: t("account.privacy.flash.not_ready")
        return
      end

      redirect_to rails_blob_path(user.data_export, disposition: "attachment")
    end
  end
end
