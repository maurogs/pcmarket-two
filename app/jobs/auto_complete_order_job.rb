# frozen_string_literal: true

# Completes an order once its buyer-protection window has elapsed.
class AutoCompleteOrderJob < ApplicationJob
  queue_as :default

  def perform(order)
    Orders::Complete.new(order: order).call
  end
end
