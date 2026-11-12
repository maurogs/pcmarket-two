# frozen_string_literal: true

module Api
  module V1
    # Base class for the versioned, token-authenticated JSON API. It is a pure
    # ActionController::API controller: no cookies, sessions, CSRF or browser
    # guard. Public endpoints inherit it directly; authenticated endpoints
    # inherit AuthenticatedController.
    class BaseController < ActionController::API
      include Pundit::Authorization
      include ActiveStorage::SetCurrent
      include Api::V1::Authentication
      include Api::V1::Locale
      include Api::V1::Pagination
      include Api::V1::ErrorHandling

      before_action :load_api_session
      around_action :switch_locale

      private

      def render_data(data, status: :ok, meta: nil)
        payload = { data: data }
        payload[:meta] = meta if meta.present?
        render json: payload, status: status
      end

      def render_resource(record, serializer, status: :ok, options: {})
        render_data(serialize(record, serializer, options: options), status: status)
      end

      def render_collection(records, serializer, meta:, status: :ok, options: {})
        data = records.map { |record| serialize(record, serializer, options: options) }
        render_data(data, status: status, meta: meta)
      end

      def serialize(record, serializer, options: {})
        serializer.new(record, **options).serializable_hash
      end

      def collection_response(relation, serializer, extra_meta: {}, options: {})
        pagy, records = if relation.is_a?(Array)
          paginate_array(relation)
        else
          paginate(relation)
        end
        set_pagination_headers(pagy)
        render_collection(
          records, serializer,
          meta: collection_meta(pagy, extra: extra_meta),
          options: options
        )
      end

      # Sends the JSON API 304 response when the request validator matches.
      def conditional_get!(etag:, last_modified: nil, public: current_user.nil?)
        response.headers["Cache-Control"] = "public, max-age=60" if public
        fresh_when(etag: etag, last_modified: last_modified, public: public)
        performed?
      end

      def cache_public_catalogue!
        response.headers["Cache-Control"] = "public, max-age=60" if current_user.nil?
      end

      def require_api_feature!(flag)
        return if Flipper.enabled?(flag)

        raise Api::V1::Error.feature_disabled
      end

      def session_payload(user, session, access_token, refresh_token)
        {
          access_token: access_token,
          refresh_token: refresh_token,
          token_type: "Bearer",
          expires_at: session.expires_at.iso8601,
          refresh_expires_at: session.refresh_expires_at.iso8601,
          session: ApiSessionSerializer.new(
            session, params: { current_session_id: session.id }
          ).serializable_hash,
          user: MeSerializer.new(user).serializable_hash
        }
      end

      def reject_inactive_user!(user)
        if user.banned?
          raise Api::V1::Error.forbidden(message_key: "api.auth.banned")
        elsif user.soft_deleted?
          raise Api::V1::Error.forbidden(message_key: "api.auth.deleted")
        elsif user.access_locked?
          raise Api::V1::Error.forbidden(message_key: "api.auth.locked")
        elsif Setting.get(:api_require_confirmation, true) && !user.confirmed?
          raise Api::V1::Error.forbidden(message_key: "api.auth.unconfirmed")
        end
      end
    end
  end
end
