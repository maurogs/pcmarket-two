class ApplicationController < ActionController::Base
  include Localization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def default_url_options
    { locale: I18n.locale }
  end
end
