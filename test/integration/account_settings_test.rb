# frozen_string_literal: true

require "test_helper"

class AccountSettingsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @user = users(:confirmed)
    sign_in @user
  end

  def create_order(status:, buyer: @user, store: stores(:confirmed_store))
    checkout = Checkout.create!(
      buyer: buyer,
      email: buyer.email,
      shipping_address: default_address_attributes.stringify_keys
    )
    Order.create!(
      checkout: checkout,
      buyer: buyer,
      store: store,
      status: status,
      paid_at: Time.current,
      subtotal_cents: 10_000,
      shipping_cents: 0,
      commission_cents: 0,
      total_cents: 10_000,
      currency: "EUR"
    )
  end

  test "the profile page renders all account sections" do
    get account_profile_path(locale: :en)

    assert_response :success
    assert_includes response.body, CGI.escapeHTML(I18n.t("account.settings.security.title", locale: :en))
    assert_includes response.body, I18n.t("account.settings.security.sessions_title", locale: :en)
    assert_includes response.body, I18n.t("account.deletion.title", locale: :en)
  end

  test "updating personal details and locale" do
    patch account_profile_path(locale: :en), params: {
      section: "profile",
      user: { first_name: "Updated", last_name: "Name", locale: "fr" }
    }

    assert_redirected_to account_profile_path(locale: :fr)
    @user.reload
    assert_equal "Updated", @user.first_name
    assert_equal "fr", @user.locale
  end

  test "changing the email sends a reconfirmation to the new address" do
    assert_emails 1 do
      patch account_profile_path(locale: :en), params: {
        section: "email",
        user: { email: "new-address@example.com" }
      }
    end

    assert_redirected_to account_profile_path(locale: :en)
    @user.reload
    assert_equal "new-address@example.com", @user.unconfirmed_email
    assert_equal "mauro@example.com", @user.email
  end

  test "changing the password requires the current password" do
    patch account_password_path(locale: :en), params: {
      user: {
        current_password: "wrong-password",
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!"
      }
    }

    assert_response :unprocessable_entity

    patch account_password_path(locale: :en), params: {
      user: {
        current_password: "Password123!",
        password: "NewPassword123!",
        password_confirmation: "NewPassword123!"
      }
    }

    assert_redirected_to account_profile_path(locale: :en)
    assert @user.reload.valid_password?("NewPassword123!")
  end

  test "the password form is hidden for Google-only accounts" do
    @user.update_columns(provider: "google_oauth2", uid: "google-1")

    get account_profile_path(locale: :en)

    assert_response :success
    assert_includes response.body, I18n.t("account.settings.security.oauth_only", locale: :en)
  end

  test "account deletion is blocked while a paid order is open" do
    create_order(status: "paid")

    post account_deletion_path(locale: :en), params: { current_password: "Password123!" }

    assert_redirected_to account_profile_path(locale: :en)
    assert_equal I18n.t("account.deletion.open_orders", locale: :en), flash[:alert]
    assert_nil @user.reload.deleted_at
  end

  test "account deletion anonymises the user, purges the avatar and archives listings" do
    @user.avatar.attach(io: StringIO.new("avatar"), filename: "avatar.png", content_type: "image/png")
    listing = listings(:published_gpu)

    post account_deletion_path(locale: :en), params: { current_password: "Password123!" }

    assert_redirected_to root_path(locale: :en)
    @user.reload
    assert @user.soft_deleted?
    assert_nil @user.first_name
    assert_nil @user.last_name
    assert_nil @user.phone
    assert_match(/\Adeleted-#{@user.id}@/, @user.email)
    assert_not @user.avatar.attached?
    assert_equal "archived", listing.reload.status
  end

  test "OAuth-only accounts confirm deletion by typing their username" do
    @user.update_columns(provider: "google_oauth2", uid: "google-2")

    post account_deletion_path(locale: :en), params: { username: "wrong" }
    assert_nil @user.reload.deleted_at

    post account_deletion_path(locale: :en), params: { username: @user.username }
    assert @user.reload.soft_deleted?
  end

  test "shipping addresses can be created, edited and deleted" do
    assert_difference "Address.count", 1 do
      post account_addresses_path(locale: :en), params: {
        address: default_address_attributes.merge(default: "1")
      }
    end
    address = @user.addresses.order(:id).last
    assert address.default?

    patch account_address_path(address, locale: :en), params: {
      address: { full_name: "Updated Buyer", city: "Madrid" }
    }
    assert_equal "Updated Buyer", address.reload.full_name

    assert_difference "Address.count", -1 do
      delete account_address_path(address, locale: :en)
    end
  end

  test "marketing opt-in is saved from the notification preferences screen" do
    patch notification_preferences_path(locale: :en), params: { marketing_opt_in: "1" }

    assert @user.reload.marketing_opt_in?
  end

  test "requesting a data export enqueues the job and emails a signed download link" do
    assert_enqueued_with(job: Accounts::DataExportJob) do
      post account_data_export_path(locale: :en)
    end

    assert_emails 1 do
      perform_enqueued_jobs
    end

    @user.reload
    assert @user.data_export.attached?
    assert_includes @user.data_export.download, @user.username

    token = Accounts::ExportToken.generate(@user)
    get account_data_export_path(locale: :en, token: token)
    assert_response :redirect
    assert_match %r{/rails/active_storage/}, response.location
  end

  test "data export links expire after seven days" do
    token = Accounts::ExportToken.generate(@user)

    travel 8.days do
      assert_nil Accounts::ExportToken.verify(token)
    end
  end

  test "the data export download requires the signed-in owner" do
    token = Accounts::ExportToken.generate(@user)
    sign_out @user

    get account_data_export_path(locale: :en, token: token)

    assert_redirected_to new_user_session_path(locale: :en)

    sign_in users(:seller_two)

    get account_data_export_path(locale: :en, token: token)

    assert_redirected_to root_path(locale: :en)
    assert_equal I18n.t("account.privacy.flash.invalid_link", locale: :en), flash[:alert]
  end

  test "account deletion keeps store and category listing counters consistent" do
    store = @user.store
    category = categories(:gpus)
    create_listing!(store: store, seller: @user, category: category,
                    title: "Counter check listing", price_cents: 12_345,
                    specs: { gpu_chipset: "nvidia" })

    post account_deletion_path(locale: :en), params: { current_password: "Password123!" }

    assert_equal "archived", Listing.find_by(title: "Counter check listing").status
    assert_equal Listing.published.where(store_id: store.id).count, store.reload.listings_count
    assert_equal Listing.published.where(category_id: category.id).count, category.reload.listings_count
  end
end
