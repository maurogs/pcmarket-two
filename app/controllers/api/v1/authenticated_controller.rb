# frozen_string_literal: true

module Api
  module V1
    # Every endpoint below this class requires a valid bearer token.
    class AuthenticatedController < BaseController
      before_action :authenticate_api_user!
    end
  end
end
