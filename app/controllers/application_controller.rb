class ApplicationController < ActionController::Base
  include Localization
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale
  before_action :enforce_maintenance_mode
  before_action :merge_guest_cart
  helper_method :current_cart, :impersonating?, :current_country

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

  # Features that are shipped dark stay completely invisible: every route,
  # action and UI entry point behind the flag must 404 while it is off.
  def require_feature!(flag)
    raise ActiveRecord::RecordNotFound unless Flipper.enabled?(flag)
  end

  def current_cart
    @current_cart ||= if user_signed_in?
      Cart.find_or_initialize_by(user: current_user)
    else
      token = cookies.signed[:cart_token]
      (token.present? && Cart.find_by(token: token)) || Cart.new
    end
  end

  def persistent_cart
    cart = current_cart
    cart.save! if cart.new_record?
    cookies.signed[:cart_token] = {
      value: cart.token,
      expires: 1.year.from_now,
      httponly: true,
      same_site: :lax
    } if cart.guest?
    cart
  end

  # When the marketplace is in maintenance mode, visitors see a translated 503
  # page. Staff can keep browsing, and Devise routes stay open so an admin can
  # sign in to switch it off.
  def enforce_maintenance_mode
    return unless Setting.get(:maintenance_mode, false)
    return if devise_controller?
    return if user_signed_in? && (current_user.admin? || current_user.moderator?)

    response.set_header("Retry-After", "3600")
    respond_to do |format|
      format.html { render "maintenance/show", layout: "maintenance", status: :service_unavailable }
      format.any { head :service_unavailable }
    end
  end

  def merge_guest_cart
    return unless user_signed_in?

    token = cookies.signed[:cart_token]
    return if token.blank?

    guest_cart = Cart.find_by(token: token)
    if guest_cart.present?
      user_cart = Cart.find_or_initialize_by(user: current_user)
      user_cart.save! if user_cart.new_record?
      Carts::Merge.new(guest_cart: guest_cart, user_cart: user_cart).call
      @current_cart = user_cart
    end

    cookies.delete(:cart_token)
  end

  # True while an admin is browsing as another user. Impersonated sessions can
  # never reach staff screens or payment-setting pages.
  def impersonating?
    session[:impersonator_id].present?
  end

  # The visitor's country drives legal content and the footer selector. Only
  # launched countries are accepted; anything else falls back to the first
  # launched country (Spain today).
  def current_country
    @current_country ||= begin
      launched = Country.launched_codes
      requested = cookies[:country].to_s.upcase
      code = launched.include?(requested) ? requested : launched.first
      countries = Country.launched_countries
      countries.find { |country| country.code == code } ||
        countries.find { |country| country.code == "ES" }
    end
  end

  def default_url_options
    # Spanish is served unprefixed: a nil locale drops the optional segment,
    # while keeping the key so positional route helpers still map ids correctly.
    { locale: (I18n.locale == I18n.default_locale ? nil : I18n.locale) }
  end
end
