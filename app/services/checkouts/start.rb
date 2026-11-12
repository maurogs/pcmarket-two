# frozen_string_literal: true

module Checkouts
  # Validates the cart, reserves stock in one transaction, splits the purchase
  # into one order per seller, freezes prices and starts the payment.
  class Start
    Result = Struct.new(:success, :checkout, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(cart:, buyer:, params:, gateway: Payments.gateway)
      @cart = cart
      @buyer = buyer
      @params = params.to_h.with_indifferent_access
      @gateway = gateway
    end

    def call
      return failure("checkout.errors.guest_disabled") if @buyer.nil? && !Flipper.enabled?(:guest_checkout)
      return failure("checkout.errors.terms_required") unless accepted_terms?
      return failure("checkout.errors.empty_cart") if @cart.items.empty?

      existing = existing_checkout
      if existing.present?
        return Result.new(success: true, checkout: existing, errors: []) if existing.pending? || existing.paid?

        return Result.new(success: false, checkout: existing,
                            errors: [ I18n.t("checkout.errors.payment_failed") ])
      end

      address, address_errors = resolve_address
      return Result.new(success: false, checkout: nil, errors: address_errors) if address.nil?

      checkout = build_checkout(address)
      return Result.new(success: false, checkout: nil, errors: checkout.errors.full_messages) unless checkout.valid?

      run_checkout(checkout, address)
    end

    private

    def cart_items_for_checkout
      scope = @cart.items
      if @params[:buy_now_listing_id].present?
        scope = scope.where(listing_id: @params[:buy_now_listing_id])
      end

      scope.includes(listing: [ :store, :seller, { photos: { image_attachment: :blob } } ]).to_a
    end

    def accepted_terms?
      ActiveModel::Type::Boolean.new.cast(@params[:terms_accepted])
    end

    def existing_checkout
      key = @params[:idempotency_key].presence
      return if key.blank?

      Checkout.find_by(idempotency_key: key)
    end

    def resolve_address
      if @buyer.present? && @params[:address_id].present?
        address = @buyer.addresses.find_by(id: @params[:address_id])
        return [ nil, [ I18n.t("checkout.errors.address_not_found") ] ] if address.nil?

        return [ address, [] ]
      end

      address = Address.new(address_attributes)
      address.user = @buyer if @buyer.present?
      return [ nil, address.errors.full_messages ] unless address.valid?

      persist_address(address)
      [ address, [] ]
    end

    def address_attributes
      raw = @params[:address]
      return {} if raw.blank?

      raw.to_h.with_indifferent_access.slice(
        :full_name, :line1, :line2, :city, :region_id, :postal_code, :country_code, :phone
      )
    end

    def persist_address(address)
      return if @buyer.blank? || !ActiveModel::Type::Boolean.new.cast(@params[:save_address])

      address.default = true if @buyer.addresses.empty?
      address.save!
    end

    def build_checkout(address)
      Checkout.new(
        buyer: @buyer,
        email: @buyer&.email.presence || @params[:email],
        shipping_address: address.to_snapshot,
        status: "pending",
        idempotency_key: @params[:idempotency_key].presence
      )
    end

    def run_checkout(checkout, address)
      error = nil
      gateway_result = nil

      Checkout.transaction do
        @cart.lock!
        items = lock_cart_listings(cart_items_for_checkout)

        if items.empty? || !items.all?(&:purchasable?)
          error = I18n.t("checkout.errors.unavailable_items")
          raise ActiveRecord::Rollback
        end

        groups = items.group_by { |item| item.listing.store }
        fulfilments = groups.transform_values { |group_items| fulfilment_for(group_items) }
        groups.each do |store, group_items|
          next if reserve_group(group_items)

          error = I18n.t("checkout.errors.out_of_stock")
          raise ActiveRecord::Rollback
        end

        checkout.save!
        checkout.shipping_address = address.to_snapshot
        groups.each do |store, group_items|
          build_order(checkout, store, group_items, fulfilments[store])
        end
        checkout.update!(
          subtotal_cents: checkout.orders.sum(&:subtotal_cents),
          shipping_cents: checkout.orders.sum(&:shipping_cents),
          total_cents: checkout.orders.sum(&:total_cents)
        )

        gateway_result = @gateway.create_payment(checkout: checkout)
        if gateway_result.success?
          checkout.update!(payment_intent_id: gateway_result.payment_intent_id,
                           payment_client_secret: gateway_result.client_secret)
        else
          fail_checkout(checkout)
        end
      end

      return Result.new(success: false, checkout: nil, errors: [ error ]) if error.present?

      if gateway_result&.success?
        Result.new(success: true, checkout: checkout, errors: [])
      else
        Result.new(success: false, checkout: checkout, errors: [ I18n.t("checkout.errors.payment_failed") ])
      end
    end

    def reserve_group(group_items)
      group_items.all? { |item| item.listing.reserve_stock!(item.quantity) }
    end

    # Every checkout locks the cart's listings in the same primary-key order, in
    # a single query, so concurrent carts holding the same listings can never
    # acquire the row locks in opposite orders and deadlock. The cart items then
    # point at the locked instances used by the reserving and order building.
    def lock_cart_listings(items)
      return items if items.empty?

      locked_by_id = Listing.where(id: items.map(&:listing_id)).order(:id).lock.index_by(&:id)

      items.each { |item| item.listing = locked_by_id.fetch(item.listing_id) }
      items
    end

    def fulfilment_for(group_items)
      requested = @params[:fulfilment].to_h.with_indifferent_access[group_items.first.listing.store_id.to_s]
      shipping_allowed = group_items.all? { |item| item.listing.shipping? || item.listing.shipping_and_pickup? }
      pickup_allowed = group_items.all? { |item| item.listing.local_pickup? || item.listing.shipping_and_pickup? }

      if requested == "local_pickup" && pickup_allowed
        "local_pickup"
      elsif requested == "shipping" && shipping_allowed
        "shipping"
      elsif shipping_allowed
        "shipping"
      else
        "local_pickup"
      end
    end

    def build_order(checkout, store, group_items, fulfilment)
      subtotal = group_items.sum { |item| item.effective_unit_price_cents * item.quantity }
      shipping = if fulfilment == "local_pickup"
       0
      else
        group_items.map { |item| item_shipping(item) }.max.to_i
      end

      order = checkout.orders.create!(
        buyer: @buyer,
        store: store,
        status: "pending_payment",
        fulfilment: fulfilment,
        subtotal_cents: subtotal,
        shipping_cents: shipping,
        commission_cents: Order.commission_for(subtotal),
        total_cents: subtotal + shipping,
        currency: group_items.first.listing.currency.presence || "EUR"
      )

      group_items.each do |item|
        order.items.create!(
          listing: item.listing,
          quantity: item.quantity,
          unit_price_cents: item.effective_unit_price_cents,
          shipping_cents: item_shipping(item),
          title: item.listing.title,
          seller_name: store.name,
          photo_url: photo_url_for(item.listing),
          specs: item.listing.specs || {}
        )
      end

      order.events.create!(event: "created", actor: @buyer, data: { store_id: store.id })
      order
    end

    def item_shipping(item)
      item.listing.free_shipping? ? 0 : item.listing.shipping_price_cents.to_i
    end

    def photo_url_for(listing)
      photo = listing.primary_photo
      return if photo.blank? || !photo.image.attached?

      Rails.application.routes.url_helpers.rails_blob_path(photo.image, only_path: true)
    end

    def fail_checkout(checkout)
      checkout.update!(status: "failed")
      checkout.orders.each do |order|
        Orders::ReleaseStock.new(order: order).call
        order.cancel! if order.may_cancel?
        order.events.create!(event: "payment_failed", actor: @buyer)
      end
    end

    def failure(key)
      Result.new(success: false, checkout: nil, errors: [ I18n.t(key) ])
    end
  end
end
