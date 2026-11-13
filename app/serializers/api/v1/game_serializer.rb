# frozen_string_literal: true

module Api
  module V1
    class GameSerializer < BaseSerializer
      attributes :id, :name, :slug, :position, :min_gpu_tier, :min_cpu_tier

      attribute :cover_url do |game|
        attachment_url(game.cover, variant: :card)
      end
    end
  end
end
