# frozen_string_literal: true

module Orders
  # Records a buyer's problem report as an order event. Dispute evidence and
  # the staff resolution flow remain a future phase, but the report is durable
  # and visible on the order timeline.
  class ReportProblem
    def initialize(order:, actor:, reason: nil, details: nil)
      @order = order
      @actor = actor
      @reason = reason
      @details = details
    end

    def call
      return false unless @order.buyer_id == @actor.id

      @order.events.create!(
        event: "problem_reported",
        actor: @actor,
        data: { reason: @reason.presence, details: @details.presence }
      )
      true
    end
  end
end
