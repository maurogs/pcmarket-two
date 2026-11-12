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
    self
  end

  attr_reader :tab

  # Each tab loads only its own rows; the other tab's badge uses a COUNT.
  def favourites
    return [] unless tab == "favourites"

    @favourites ||= @user.favourites
                         .includes(
                           listing: [
                             { photos: { image_attachment: :blob } },
                             :tags,
                             :category,
                             :region,
                             :store,
                             :seller
                           ]
                         )
                         .recent
                         .to_a
  end

  def follows
    return [] unless tab == "following"

    @follows ||= @user.follows
                      .includes(store: { logo_attachment: :blob })
                      .recent
                      .to_a
  end

  def favourite_count
    @favourites ? favourites.size : @user.favourites.count
  end

  def following_count
    @follows ? follows.size : @user.follows.count
  end

  private

  def normalized_tab
    value = @params["tab"].to_s
    TABS.include?(value) ? value : "favourites"
  end
end
