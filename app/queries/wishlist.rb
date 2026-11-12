# frozen_string_literal: true

# Owns the wishlist page query: the active tab, the favourited listings with
# their card associations and the followed stores. The controller only renders.
class Wishlist
  TABS = %w[favourites following].freeze

  def initialize(user:, params:)
    @user = user
    raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    @params = raw_params.deep_stringify_keys
  end

  def call
    @tab = normalized_tab
    @favourites = @user.favourites
                       .includes(
                         listing: [
                           { photos: { image_attachment: :blob } },
                           :tags,
                           :category,
                           :region,
                           { store: { logo_attachment: :blob } }
                         ]
                       )
                       .recent
                       .to_a
    @follows = @user.follows
                    .includes(store: { logo_attachment: :blob })
                    .recent
                    .to_a
    self
  end

  attr_reader :tab, :favourites, :follows

  def favourite_count
    favourites.size
  end

  def following_count
    follows.size
  end

  private

  def normalized_tab
    value = @params["tab"].to_s
    TABS.include?(value) ? value : "favourites"
  end
end
