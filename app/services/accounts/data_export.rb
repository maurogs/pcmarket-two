# frozen_string_literal: true

module Accounts
  # Builds the JSON payload for a data-portability request.
  class DataExport
    def initialize(user)
      @user = user
    end

    def as_json
      {
        exported_at: Time.current.iso8601,
        profile: profile,
        addresses: addresses,
        listings: listings,
        orders: orders,
        messages: messages,
        reviews: reviews,
        saved_searches: saved_searches
      }
    end

    private

    attr_reader :user

    def profile
      {
        username: user.username,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        locale: user.locale,
        country_code: user.country_code,
        created_at: user.created_at.iso8601
      }
    end

    def addresses
      user.addresses.map do |address|
        address.attributes.slice(
          "full_name", "line1", "line2", "city", "postal_code", "country_code", "phone"
        ).merge("province" => address.province_name)
      end
    end

    def listings
      user.listings.order(:id).map do |listing|
        {
          id: listing.id,
          title: listing.title,
          status: listing.status,
          price_cents: listing.price_cents,
          currency: listing.currency,
          created_at: listing.created_at.iso8601
        }
      end
    end

    def orders
      buyer_orders = user.orders.order(:id).map do |order|
        order_row(order, role: "buyer")
      end
      seller_orders = user.store ? user.store.orders.order(:id).map { |order| order_row(order, role: "seller") } : []
      buyer_orders + seller_orders
    end

    def order_row(order, role:)
      {
        number: order.number,
        role: role,
        status: order.status,
        total_cents: order.total_cents,
        currency: order.currency,
        created_at: order.created_at.iso8601
      }
    end

    def messages
      user.messages.order(:id).map do |message|
        {
          conversation_id: message.conversation_id,
          body: message.body,
          kind: message.kind,
          created_at: message.created_at.iso8601
        }
      end
    end

    def reviews
      authored = user.reviews.order(:id).map do |review|
        {
          direction: "authored",
          rating: review.rating,
          body: review.body,
          seller_reply: review.seller_reply,
          created_at: review.created_at.iso8601
        }
      end
      received = user.store ? user.store.reviews.order(:id).map do |review|
        {
          direction: "received",
          rating: review.rating,
          body: review.body,
          created_at: review.created_at.iso8601
        }
      end : []
      authored + received
    end

    def saved_searches
      user.saved_searches.order(:id).map do |saved_search|
        {
          name: saved_search.name,
          query_params: saved_search.query_params,
          frequency: saved_search.frequency,
          email_alerts: saved_search.email_alerts,
          created_at: saved_search.created_at.iso8601
        }
      end
    end
  end
end
