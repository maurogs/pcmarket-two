# frozen_string_literal: true

module WishlistHelper
  # Sold and no-longer-visible listings stay in the wishlist but are greyed out.
  def wishlist_availability_label(listing)
    return if listing.publicly_visible?

    listing.sold? ? t("wishlist.sold") : t("wishlist.unavailable")
  end
end
