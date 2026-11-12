# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update]

    def index
      authorize User, :index?, policy_class: Admin::UserPolicy

      @query = Admin::UserQuery.new(params: params)

      respond_to do |format|
        format.html
        format.csv do
          send_data export_csv, filename: "users-#{Date.current}.csv",
                                type: "text/csv"
        end
      end
    end

    def show
      authorize @user, policy_class: Admin::UserPolicy

      @store = @user.store
      @buyer_orders = @user.orders.includes(:store).recent_first.limit(20)
      @seller_orders = @store ? @store.orders.includes(:buyer).recent_first.limit(20) : Order.none
      @listings = @user.listings.includes(:store, :category).order(created_at: :desc).limit(20)
      @reports_against = Report.where(reportable: @user).includes(:reporter).order(created_at: :desc)
      @reviews = Review.where(reviewer_id: @user.id).includes(:store).newest_first.limit(20)
      @audit_logs = AdminAuditLog.where(auditable: @user).newest_first.limit(20)
    end

    def edit
      authorize @user, policy_class: Admin::UserPolicy
    end

    def update
      authorize @user, policy_class: Admin::UserPolicy

      if @user.update(user_params)
        changes = @user.saved_changes.except("updated_at", "encrypted_password")
        audit!(action: "user.updated", auditable: @user, changes: changes)
        redirect_to admin_user_path(@user), notice: t("admin.users.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :username, :email, :phone, :locale,
        :country_code, :marketing_opt_in
      )
    end

    def export_csv
      Admin::CsvExport.new(
        headers: [
          t("admin.users.csv.id"), t("admin.users.csv.username"), t("admin.users.csv.email"),
          t("admin.users.csv.role"), t("admin.users.csv.status"),
          t("admin.users.csv.stores"), t("admin.users.csv.sign_in_count"),
          t("admin.users.csv.last_sign_in_at"), t("admin.users.csv.created_at")
        ],
        rows: Admin::UserQuery.new(params: params).export_records.map do |user|
          [
            user.id, user.username, user.email, user.role, user_status(user),
            user.store&.name, user.sign_in_count, user.last_sign_in_at&.iso8601,
            user.created_at.iso8601
          ]
        end
      ).to_csv
    end

    def user_status(user)
      return "deleted" if user.soft_deleted?
      return "banned" if user.banned?
      return "unconfirmed" if user.confirmed_at.nil?

      "active"
    end
  end
end
