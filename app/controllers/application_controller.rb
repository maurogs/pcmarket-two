class ApplicationController < ActionController::Base
  include Localization
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  rescue_from Pundit::NotAuthorizedError do
    respond_to do |format|
      format.html do
        redirect_back fallback_location: root_path,
                     alert: t("pundit.not_authorized")
      end
      format.json { render json: { error: t("pundit.not_authorized") }, status: :forbidden }
    end
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def default_url_options
    { locale: I18n.locale }
  end
end
