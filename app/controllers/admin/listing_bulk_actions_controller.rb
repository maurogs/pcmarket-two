# frozen_string_literal: true

module Admin
  class ListingBulkActionsController < BaseController
    ADMIN_ONLY_OPERATIONS = %w[label feature].freeze

    def create
      authorize Listing, :bulk?, policy_class: Admin::ListingPolicy

      listings = Listing.where(id: Array(params[:listing_ids]).map(&:to_i).uniq)
      operation = params[:operation].to_s

      if listings.none?
        redirect_to admin_listings_path, alert: t("admin.listings.bulk.none_selected")
        return
      end

      if ADMIN_ONLY_OPERATIONS.include?(operation) && !current_user.admin?
        redirect_to admin_listings_path, alert: t("admin.listings.bulk.admins_only")
        return
      end

      result = Admin::BulkListingAction.new(
        listings: listings,
        actor: current_user,
        operation: operation,
        reason: bulk_reason,
        label_id: params[:label_id],
        days: params[:days]
      ).call

      audit!(action: "listing.bulk", auditable: listings.first,
             changes: { operation: operation, affected: result.affected,
                        skipped: result.skipped })

      redirect_to admin_listings_path(request.query_parameters.except("page")),
                  notice: t("admin.listings.bulk.done",
                            count: result.affected, skipped: result.skipped)
    end

    private

    def bulk_reason
      return params[:reject_reason].to_s.strip if params[:reject_reason].present?

      ListingModeration.compose_reason(
        code: params[:reason_code],
        text: params[:reason_text],
        locale: I18n.locale
      )
    end
  end
end
