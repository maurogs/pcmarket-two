# frozen_string_literal: true

module Admin
  # Each route is a review of one listing: `index` is the pending queue,
  # `show` is the buyer-facing preview and `update` records the decision. The
  # moderation decision is therefore a RESTful update of that review resource.
  class ListingReviewsController < BaseController
    before_action :set_listing, only: %i[show update]

    def index
      authorize :listing, :index?, policy_class: Admin::ListingPolicy

      @queue = Admin::ModerationQueue.new(params: params).call
    end

    def show
      authorize @listing, policy_class: Admin::ListingPolicy

      @seller_profile = Admin::SellerProfile.new(listing: @listing)
      @next_listing = Admin::ModerationQueue.next_pending(@listing)
      @previous_listing = Admin::ModerationQueue.previous_pending(@listing)
      @moderations = @listing.moderations.includes(:moderator).order(created_at: :desc)
    end

    def update
      authorize @listing, policy_class: Admin::ListingPolicy

      decision = params[:decision].to_s

      case decision
      when "approve"
        moderate { Listings::Moderate.new(listing: @listing, moderator: current_user).approve! }
      when "reject"
        return redirect_to review_path, alert: t("admin.moderation.notices.reason_required") unless valid_reason_code?

        reason = compose_reason
        return redirect_to review_path, alert: t("admin.moderation.notices.reason_required") if reason.blank?

        moderate do
          Listings::Moderate.new(listing: @listing, moderator: current_user, reason: reason).reject!
        end
      else
        redirect_to review_path, alert: t("admin.moderation.notices.invalid_decision")
      end
    end

    private

    def set_listing
      @listing = Listing.with_detail_includes.friendly.find(params[:id])
    end

    def compose_reason
      ListingModeration.compose_reason(
        code: params[:reason_code],
        text: params[:reason_text],
        locale: @listing.seller.locale
      )
    end

    def valid_reason_code?
      ListingModeration::REJECTION_REASONS.include?(params[:reason_code].to_s)
    end

    def moderate
      moderation = yield
      destination = Admin::ModerationQueue.next_pending(@listing)

      if moderation
        redirect_to destination ? review_path(destination) : admin_listing_reviews_path,
                    notice: t("admin.moderation.notices.#{moderation.action}")
      else
        redirect_to destination ? review_path(destination) : admin_listing_reviews_path,
                    alert: t("admin.moderation.notices.already_moderated")
      end
    end

    def review_path(listing = @listing)
      admin_listing_review_path(listing)
    end
  end
end
