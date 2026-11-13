# frozen_string_literal: true

module Api
  module V1
    class ListingDetailSerializer < ListingCardSerializer
      attributes :description, :handling_days, :postal_code, :country_code,
                 :featured_until, :submitted_at, :sold_at

      many :photos, resource: ListingPhotoSerializer

      attribute :specs do |listing|
        resolved_specs(listing)
      end

      attribute :seller do |listing|
        UserSummarySerializer.new(listing.seller).serializable_hash
      end

      attribute :store_detail do |listing|
        StoreDetailSerializer.new(listing.store).serializable_hash
      end

      attribute :delivery_estimate do |listing|
        estimate = DeliveryEstimate.new(handling_days: listing.handling_days || 3)
        {
          ships_on: estimate.ships_on.iso8601,
          delivered_from: estimate.delivered_from.iso8601,
          delivered_to: estimate.delivered_to.iso8601
        }
      end

      attribute :similar_listing_ids do |_listing|
        Array(params[:similar_listing_ids])
      end

      private

      def resolved_specs(listing)
        specs = (listing.specs || {}).with_indifferent_access
        definitions = listing.category&.effective_attribute_definitions&.index_by(&:key) || {}

        specs.filter_map do |key, raw|
          definition = definitions[key.to_s]
          values = Array(raw).reject(&:blank?).map(&:to_s)
          next if values.empty?

          {
            key: key.to_s,
            label: definition&.name.presence || key.to_s.humanize,
            values: values.map do |value|
              option = definition&.attribute_options&.find { |candidate| candidate.value.to_s == value }
              { value: value, label: option&.label.presence || value }
            end
          }
        end
      end
    end
  end
end
