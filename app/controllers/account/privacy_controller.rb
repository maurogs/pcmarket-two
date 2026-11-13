# frozen_string_literal: true

module Account
  class PrivacyController < ApplicationController
    before_action :authenticate_user!

    def show
      authorize current_user, :show?, policy_class: AccountPolicy
    end
  end
end
