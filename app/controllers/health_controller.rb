# frozen_string_literal: true

# Liveness/readiness probe for Kamal and uptime monitors. Confirms the app can
# still reach PostgreSQL instead of only checking that the process boots.
class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.select_value("SELECT 1")
    end

    render json: { status: "ok", database: "ok" }, status: :ok
  rescue ActiveRecord::ActiveRecordError, PG::Error
    render json: { status: "unavailable", database: "error" }, status: :service_unavailable
  end
end
