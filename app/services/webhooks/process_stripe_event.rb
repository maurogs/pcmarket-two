# frozen_string_literal: true

module Webhooks
  # Applies a stored Stripe event to the marketplace domain. Errors are recorded
  # on the event and re-raised so the job can be retried; processed_at is only
  # set after a successful dispatch.
  class ProcessStripeEvent
    def initialize(webhook_event)
      @webhook_event = webhook_event
    end

    def call
      return if @webhook_event.nil? || @webhook_event.processed?

      payload = @webhook_event.payload.with_indifferent_access
      dispatch(payload)

      @webhook_event.update!(processed_at: Time.current, error: nil)
    rescue StandardError => e
      @webhook_event&.update_columns(error: e.message)
      raise
    end

    private

    def dispatch(payload)
      object = payload.dig(:data, :object) || {}

      case payload[:type]
      when "payment_intent.succeeded"
        complete_checkout(object)
      when "payment_intent.payment_failed"
        fail_checkout(object)
      when "charge.refunded"
        refund_orders(object)
      when "charge.dispute.created"
        open_dispute(object)
      when "account.updated"
        update_account(object)
      when "transfer.created", "transfer.updated"
        record_transfer(object)
      when "transfer.reversed", "transfer.failed"
        fail_transfer(object)
      end
    end

    def complete_checkout(intent)
      checkout = checkout_for_intent(intent)
      Checkouts::Complete.new(checkout: checkout).call if checkout.present?
    end

    def fail_checkout(intent)
      checkout = checkout_for_intent(intent)
      Checkouts::Fail.new(checkout: checkout).call if checkout.present?
    end

    def checkout_for_intent(intent)
      checkout_id = intent.dig(:metadata, :checkout_id)
      intent_id = intent[:id]

      checkout = Checkout.find_by(id: checkout_id) if checkout_id.present?
      return checkout if checkout.present?

      Checkout.find_by(payment_intent_id: intent_id) if intent_id.present?
    end

    def refund_orders(charge)
      orders_for_refund(charge).find_each do |order|
        order.refund! if order.may_refund?
      end
    end

    def orders_for_refund(charge)
      orders = orders_from_refund_metadata(charge)
      return orders if orders.exists?

      orders = orders_from_charge_metadata(charge)
      return orders if orders.exists?

      checkout = Checkout.find_by(payment_intent_id: charge[:payment_intent]) if charge[:payment_intent].present?
      return Order.none if checkout.nil?

      amount = charge[:amount_refunded].to_i
      matching = checkout.orders.where(total_cents: amount)
      matching.exists? ? matching : checkout.orders
    end

    def orders_from_refund_metadata(charge)
      ids = Array(charge.dig(:refunds, :data)).filter_map { |refund| refund.dig(:metadata, :order_id) }
      ids.any? ? Order.where(id: ids) : Order.none
    end

    def orders_from_charge_metadata(charge)
      order_id = charge.dig(:metadata, :order_id)
      order_id.present? ? Order.where(id: order_id) : Order.none
    end

    def open_dispute(dispute)
      return if dispute[:payment_intent].blank?

      checkout = Checkout.find_by(payment_intent_id: dispute[:payment_intent])
      return if checkout.nil?

      checkout.orders.find_each do |order|
        order.open_dispute! if order.may_open_dispute?
        notify_admins(order)
      end
    end

    def notify_admins(order)
      User.where(role: :admin).find_each do |admin|
        OrderMailer.dispute_alert(order, recipient: admin).deliver_later
      end
    end

    def update_account(account)
      store = Store.find_by(stripe_account_id: account[:id])
      return if store.nil?

      store.update!(
        payouts_enabled: account[:payouts_enabled] || false,
        charges_enabled: account[:charges_enabled] || false,
        details_submitted: account[:details_submitted] || false,
        requirements: account_requirements(account)
      )
    end

    def account_requirements(account)
      requirements = account[:requirements]
      requirements.respond_to?(:to_hash) ? requirements.to_hash : (requirements || {})
    end

    def record_transfer(transfer)
      payout = find_payout(transfer)
      return if payout.nil?

      status = transfer[:reversed] ? "failed" : "paid"
      payout.update!(status: status, stripe_transfer_id: transfer[:id],
                     error: transfer[:failure_message].presence)
    end

    def fail_transfer(transfer)
      payout = find_payout(transfer)
      return if payout.nil?

      payout.update!(status: "failed", stripe_transfer_id: transfer[:id],
                     error: transfer[:failure_message].presence)
    end

    def find_payout(transfer)
      order_id = transfer.dig(:metadata, :order_id)
      payout = Payout.find_by(order_id: order_id) if order_id.present?
      payout || Payout.find_by(stripe_transfer_id: transfer[:id])
    end
  end
end
