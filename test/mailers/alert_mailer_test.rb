# frozen_string_literal: true

require "test_helper"

class AlertMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:moderator)
    @seller = users(:confirmed)
    @store = stores(:confirmed_store)
    @listing = create_listing!(store: @store, seller: @seller, title: "Alert test GPU",
                               price_cents: 15_000)
    @saved_search = SavedSearch.create!(user: @user, name: "Alert search",
                                        category: categories(:gpus), query_params: {})
  end

  def emails_for(user)
    {
      price_drop: AlertMailer.price_drop(user, @listing),
      followed_store_new_listing: AlertMailer.followed_store_new_listing(user, @store, [ @listing ]),
      saved_search_match: AlertMailer.saved_search_match(@saved_search, @listing),
      saved_search_digest: AlertMailer.saved_search_digest(
        user, [ { saved_search: @saved_search, listings: [ @listing ] } ]
      )
    }
  end

  test "all four emails render in the recipient locale with unsubscribe headers" do
    I18n.available_locales.each do |locale|
      @user.update!(locale: locale.to_s)
      emails_for(@user).each do |kind, email|
        assert_equal [ @user.email ], email.to
        assert_includes email.text_part.body.to_s, "/#{locale}/unsubscribe?token=",
                        "#{kind} is missing the unsubscribe link in #{locale}"
        assert_includes email.text_part.body.to_s,
                        I18n.t("alert_mailer.footer.unsubscribe", locale: locale)
        assert_includes email["List-Unsubscribe"].to_s, "/#{locale}/unsubscribe?token="
        assert_equal "List-Unsubscribe=One-Click",
                     email["List-Unsubscribe-Post"].to_s
      end
    end
  end

  test "subjects are translated in the recipient locale" do
    @user.update!(locale: "fr")
    emails = emails_for(@user)

    assert_equal I18n.t("alert_mailer.price_drop.subject", title: @listing.title, locale: :fr),
                 emails[:price_drop].subject
    assert_equal I18n.t("alert_mailer.followed_store_new_listing.subject",
                        store: @store.name, locale: :fr),
                 emails[:followed_store_new_listing].subject
    assert_equal I18n.t("alert_mailer.saved_search_match.subject",
                        name: @saved_search.name, locale: :fr),
                 emails[:saved_search_match].subject
    assert_equal I18n.t("alert_mailer.saved_search_digest.subject", locale: :fr),
                 emails[:saved_search_digest].subject
  end

  test "price drop and saved search emails use the recipient locale in the HTML body" do
    @user.update!(locale: "de")
    price_drop = AlertMailer.price_drop(@user, @listing)
    match = AlertMailer.saved_search_match(@saved_search, @listing)

    assert_includes price_drop.html_part.body.to_s,
                    I18n.t("alert_mailer.price_drop.cta", locale: :de)
    assert_includes match.html_part.body.to_s,
                    I18n.t("alert_mailer.saved_search_match.cta", locale: :de)
  end
end
