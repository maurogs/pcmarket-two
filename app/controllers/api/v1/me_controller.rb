# frozen_string_literal: true

module Api
  module V1
    class MeController < AuthenticatedController
      def show
        authorize current_user, :show?, policy_class: AccountPolicy
        render_resource(current_user, MeSerializer)
      end

      def update
        authorize current_user, :update?, policy_class: AccountPolicy
        attach_avatar

        result = ProfileUpdate.new(
          user: current_user,
          attributes: profile_params,
          preferences: params[:notification_preferences]
        ).call

        if result.success?
          render_resource(current_user.reload, MeSerializer)
        else
          raise Api::V1::Error.validation_failed(
            details: { base: result.errors }
          )
        end
      end

      def destroy
        authorize current_user, :destroy?, policy_class: AccountPolicy
        raise Api::V1::Error.validation_failed(details: confirmation_error) unless confirmation_valid?

        result = Accounts::Delete.new(user: current_user).call
        raise Api::V1::Error.conflict(message_key: "api.me.cannot_delete") unless result.success?

        current_user.api_sessions.update_all(revoked_at: Time.current, updated_at: Time.current)
        render_data({ deleted: true })
      end

      private

      def profile_params
        params.fetch(:user, params).permit(
          :first_name, :last_name, :username, :phone, :locale,
          :country_code, :marketing_opt_in
        )
      end

      def attach_avatar
        signed_id = params[:avatar_signed_id]
        return if signed_id.blank?

        blob = ActiveStorage::Blob.find_signed!(signed_id)
        current_user.avatar.attach(blob)
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        raise Api::V1::Error.validation_failed(
          details: { avatar: [ I18n.t("api.errors.invalid_signed_id", locale: error_locale) ] }
        )
      end

      def confirmation_valid?
        if current_user.oauth_only?
          params[:username].to_s == current_user.username
        else
          current_user.valid_password?(params[:current_password].to_s)
        end
      end

      def confirmation_error
        if current_user.oauth_only?
          { username: [ I18n.t("account.deletion.invalid_confirmation", locale: error_locale) ] }
        else
          { current_password: [ I18n.t("account.deletion.invalid_confirmation", locale: error_locale) ] }
        end
      end
    end
  end
end
