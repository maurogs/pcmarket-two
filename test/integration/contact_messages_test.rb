# frozen_string_literal: true

require "test_helper"

class ContactMessagesTest < ActionDispatch::IntegrationTest
  def valid_params(overrides = {})
    {
      contact_message: {
        name: "Marta López",
        email: "marta@example.com",
        topic: "buying",
        order_number: "PCM-2026-000123",
        message: "I need help with an order that has not arrived yet."
      }.merge(overrides)
    }
  end

  test "renders the contact form" do
    get contact_messages_path

    assert_response :success
    assert_includes response.body, I18n.t("contact.title")
    assert_includes response.body, I18n.t("contact.form.message")
  end

  test "stores a message and enqueues the support email" do
    assert_difference "ContactMessage.count", 1 do
      post contact_messages_path, params: valid_params
    end

    assert_redirected_to contact_messages_path
    assert_equal I18n.t("contact.flash.sent"), flash[:notice]
    assert_enqueued_emails 1
  end

  test "honeypot submissions are silently discarded" do
    assert_no_difference "ContactMessage.count" do
      post contact_messages_path, params: valid_params.merge(website: "https://spam.example")
    end

    assert_redirected_to contact_messages_path
    assert_equal I18n.t("contact.flash.sent"), flash[:notice]
  end

  test "rejects invalid messages" do
    assert_no_difference "ContactMessage.count" do
      post contact_messages_path, params: valid_params(message: "short")
    end

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("form.errors.heading")
  end

  test "rate limits repeated messages from the same address" do
    3.times do |index|
      ContactMessage.create!(
        name: "Marta López",
        email: "marta@example.com",
        topic: "general",
        message: "Previous message number #{index} with enough text."
      )
    end

    assert_no_difference "ContactMessage.count" do
      post contact_messages_path, params: valid_params
    end

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("contact.errors.rate_limited")
  end
end
