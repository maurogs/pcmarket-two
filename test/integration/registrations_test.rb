# frozen_string_literal: true

require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "sign up requires accepting the terms" do
    assert_no_difference [ "User.count", "ActionMailer::Base.deliveries.size" ] do
      post user_registration_path(locale: :en), params: {
        user: {
          username: "newbie",
          email: "newbie@example.com",
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    assert_response 422
  end

  test "sign up with accepted terms creates the user and sends confirmation" do
    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post user_registration_path(locale: :en), params: {
          user: {
            username: "newbie",
            email: "newbie@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            marketing_opt_in: "1",
            terms_accepted: "1"
          }
        }
      end
    end

    assert_response :redirect

    user = User.find_by!(email: "newbie@example.com")
    assert user.terms_accepted_at.present?
    assert user.marketing_opt_in?
    assert_not user.confirmed?
    assert_equal "Confirmation instructions", ActionMailer::Base.deliveries.last.subject
  end

  test "sign up form renders the terms checkbox" do
    get new_user_registration_path(locale: :en)

    assert_response :success
    assert_includes response.body, 'name="user[terms_accepted]"'
    assert_includes response.body, I18n.t("auth.sign_up.title", locale: :en)
  end
end
