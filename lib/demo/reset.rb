# frozen_string_literal: true

module Demo
  # Removes rows created by Demo::Seed. Scopes every deletion to demo-tagged
  # users, stores and listings (plus rows that hang off them), so a real
  # development account, listing or order is never touched.
  class Reset
    attr_reader :logger, :removed

    def initialize(logger: Rails.logger)
      @logger = logger
      @removed = Hash.new(0)
    end

    def call
      ActiveRecord::Base.transaction do
        user_ids = User.where(demo: true).pluck(:id)
        store_ids = Store.where(demo: true).pluck(:id)
        listing_ids = Listing.where(demo: true).pluck(:id)
        return @removed if user_ids.empty? && store_ids.empty? && listing_ids.empty?

        order_ids = Order.where(buyer_id: user_ids).or(Order.where(store_id: store_ids)).pluck(:id)
        checkout_ids = Checkout.where(buyer_id: user_ids).pluck(:id)
        checkout_ids.concat(Order.where(id: order_ids).pluck(:checkout_id))
        conversation_ids = Conversation.where(buyer_id: user_ids)
                                        .or(Conversation.where(seller_id: user_ids))
                                        .or(Conversation.where(store_id: store_ids))
                                        .pluck(:id)
        photo_ids = ListingPhoto.where(listing_id: listing_ids).pluck(:id)

        blob_ids = ActiveStorage::Attachment.where(record_type: "ListingPhoto", record_id: photo_ids)
                                            .pluck(:blob_id)
        blob_ids.concat(
          ActiveStorage::Attachment.where(record_type: "Store", record_id: store_ids).pluck(:blob_id)
        )

        delete_reports(user_ids, store_ids, listing_ids, conversation_ids)
        delete_notifications(user_ids)
        delete_messages(conversation_ids, user_ids)
        delete_offers(listing_ids, user_ids, conversation_ids)
        delete_conversations(conversation_ids)
        delete_reviews(order_ids, user_ids, store_ids)
        delete_orders(order_ids)
        delete_checkouts(checkout_ids)
        delete_carts(user_ids, listing_ids)
        delete_social(user_ids, store_ids, listing_ids)
        delete_listing_dependents(listing_ids, photo_ids)
        delete_attachments(photo_ids, store_ids)
        delete_listings(listing_ids)
        delete_stores(store_ids)
        delete_users(user_ids)
        purge_blobs(blob_ids.compact.uniq)
      end

      Rails.cache.delete(Demo::ImageCredits::CACHE_KEY)
      log("demo data removed")
      @removed
    end

    private

    def delete_reports(user_ids, store_ids, listing_ids, conversation_ids)
      message_ids = Message.where(conversation_id: conversation_ids).pluck(:id)
      scope = Report.where(reporter_id: user_ids)
                    .or(Report.where(reportable_type: "Listing", reportable_id: listing_ids))
                    .or(Report.where(reportable_type: "Store", reportable_id: store_ids))
                    .or(Report.where(reportable_type: "Message", reportable_id: message_ids))
      count("reports", scope.delete_all)
    end

    def delete_notifications(user_ids)
      count("notifications", Notification.where(recipient_id: user_ids).delete_all)
      count("notification_preferences", NotificationPreference.where(user_id: user_ids).delete_all)
    end

    def delete_messages(conversation_ids, user_ids)
      scope = Message.where(conversation_id: conversation_ids).or(Message.where(sender_id: user_ids))
      count("messages", scope.delete_all)
    end

    def delete_offers(listing_ids, user_ids, conversation_ids)
      scope = Offer.where(listing_id: listing_ids)
                   .or(Offer.where(buyer_id: user_ids))
                   .or(Offer.where(offerer_id: user_ids))
                   .or(Offer.where(conversation_id: conversation_ids))
      count("offers", scope.delete_all)
    end

    def delete_conversations(conversation_ids)
      count("conversations", Conversation.where(id: conversation_ids).delete_all)
    end

    def delete_reviews(order_ids, user_ids, store_ids)
      scope = Review.where(order_id: order_ids)
                    .or(Review.where(reviewer_id: user_ids))
                    .or(Review.where(store_id: store_ids))
      count("reviews", scope.delete_all)
    end

    def delete_orders(order_ids)
      count("order_items", OrderItem.where(order_id: order_ids).delete_all)
      count("order_events", OrderEvent.where(order_id: order_ids).delete_all)
      count("order_notes", OrderNote.where(order_id: order_ids).delete_all)
      count("payouts", Payout.where(order_id: order_ids).delete_all)
      count("orders", Order.where(id: order_ids).delete_all)
    end

    def delete_checkouts(checkout_ids)
      count("checkouts", Checkout.where(id: checkout_ids).delete_all)
    end

    def delete_carts(user_ids, listing_ids)
      cart_ids = Cart.where(user_id: user_ids).pluck(:id)
      count("cart_items", CartItem.where(cart_id: cart_ids).or(CartItem.where(listing_id: listing_ids)).delete_all)
      count("carts", Cart.where(id: cart_ids).delete_all)
    end

    def delete_social(user_ids, store_ids, listing_ids)
      count("favourites", Favourite.where(user_id: user_ids).or(Favourite.where(listing_id: listing_ids)).delete_all)
      count("follows", Follow.where(follower_id: user_ids).or(Follow.where(store_id: store_ids)).delete_all)
      count("saved_searches", SavedSearch.where(user_id: user_ids).delete_all)
      count("blocks", Block.where(blocker_id: user_ids).or(Block.where(blocked_id: user_ids)).delete_all)
      count("listing_views", ListingView.where(listing_id: listing_ids).delete_all)
      count("listing_tags", ListingTag.where(listing_id: listing_ids).delete_all)
      count("listing_moderations", ListingModeration.where(listing_id: listing_ids).delete_all)
    end

    def delete_listing_dependents(listing_ids, photo_ids)
      count("cart_items", CartItem.where(listing_id: listing_ids).delete_all)
      count("listing_photos", ListingPhoto.where(id: photo_ids).delete_all)
      count("listing_tags", ListingTag.where(listing_id: listing_ids).delete_all)
      count("listing_moderations", ListingModeration.where(listing_id: listing_ids).delete_all)
    end

    def delete_attachments(photo_ids, store_ids)
      count("attachments",
            ActiveStorage::Attachment.where(record_type: "ListingPhoto", record_id: photo_ids).delete_all)
      count("attachments",
            ActiveStorage::Attachment.where(record_type: "Store", record_id: store_ids).delete_all)
    end

    def delete_listings(listing_ids)
      count("listings", Listing.where(id: listing_ids).delete_all)
    end

    def delete_stores(store_ids)
      count("stores", Store.where(id: store_ids).delete_all)
    end

    def delete_users(user_ids)
      count("addresses", Address.where(user_id: user_ids).delete_all)
      count("api_sessions", ApiSession.where(user_id: user_ids).delete_all)
      count("device_tokens", DeviceToken.where(user_id: user_ids).delete_all)
      count("buyback_requests", BuybackRequest.where(user_id: user_ids).delete_all)
      count("cookie_consents", CookieConsent.where(user_id: user_ids).delete_all)
      count("users", User.where(id: user_ids).delete_all)
    end

    def purge_blobs(blob_ids)
      ActiveStorage::Blob.where(id: blob_ids).find_each(&:purge)
    end

    def count(key, amount)
      @removed[key] += amount.to_i
    end

    def log(_message)
      return unless logger

      kept = @removed.reject { |_key, value| value.zero? }
      logger.info("[demo:reset] removed #{kept.map { |key, value| "#{value} #{key}" }.join(', ')}")
    end
  end
end
