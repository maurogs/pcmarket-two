Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OmniAuth callbacks must live outside the optional locale scope.
  devise_for :users, only: :omniauth_callbacks,
                     controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Stripe posts here without a locale prefix and verifies signatures itself.
  post "webhooks/stripe", to: "webhooks/stripe#create", as: :stripe_webhook

  # Human-readable API documentation. Only this page loads the Redoc bundle.
  get "api/docs", to: "api/docs#show", as: :api_docs

  # Versioned JSON API for the native apps. It lives outside the locale scope:
  # clients negotiate locale with Accept-Language instead of URL prefixes.
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :current_session, only: :destroy, path: "sessions/current",
                                 controller: "current_sessions"
      resources :sessions, only: %i[index create destroy]
      resource :session_refresh, only: :create
      resources :registrations, only: :create
      resource :password_reset, only: :create
      resources :google_sessions, only: :create
      resource :me, only: %i[show update destroy], controller: "me"
      resources :device_tokens, only: %i[create destroy]

      # Public catalogue.
      resources :categories, only: %i[index show]
      resources :attribute_definitions, only: :index
      resources :tags, only: :index
      resources :regions, only: :index
      resources :countries, only: :index
      resources :listings, only: %i[index show]
      resources :stores, only: :show do
        resources :listings, only: :index, controller: "store_listings"
        resources :reviews, only: :index, controller: "store_reviews"
      end
      namespace :pc_finder do
        resources :games, only: :index
        resources :recommendations, only: :index
      end
      resources :legal_pages, only: :show, param: :kind
      resource :public_settings, only: :show, path: "settings/public",
                                 controller: "public_settings"

      # Buyer.
      resources :favourites, only: %i[index create destroy]
      resources :follows, only: %i[index create destroy]
      resources :saved_searches, only: %i[index create update destroy]
      resource :cart, only: :show, controller: "carts"
      resources :cart_items, only: %i[create update destroy]
      resources :addresses, only: %i[index create update destroy]
      resources :checkouts, only: %i[create show]
      resources :orders, only: %i[index show] do
        resource :review, only: %i[create update], controller: "reviews"
        resource :delivery_confirmation, only: :create,
                                         controller: "order_delivery_confirmations"
        resource :cancellation, only: :create,
                                controller: "order_cancellations"
        resource :problem_report, only: :create,
                                  controller: "order_problem_reports"
      end

      # Seller.
      resource :my_store, only: %i[show create update], path: "store",
                          controller: "my_stores"
      resource :vacation, only: %i[show update], controller: "store_vacations"
      resource :stripe_connect, only: :create, controller: "stripe_connects"
      resources :direct_uploads, only: :create

      namespace :sell do
        resources :listings, only: %i[index create update destroy] do
          resource :submission, only: :create, controller: "submissions"
          resource :archival, only: :create, controller: "archivals"
          resource :republication, only: :create, controller: "republications"
        end
        resources :orders, only: %i[index show] do
          resource :shipment, only: :create, controller: "order_shipments"
          resource :cancellation, only: :create, controller: "order_cancellations"
        end
        resource :analytics, only: :show, controller: "analytics"
      end

      # Messaging.
      resources :conversations, only: %i[index show create] do
        resources :messages, only: %i[index create]
        resource :read, only: :create, controller: "conversation_reads"
      end
      resources :offers, only: %i[create update]
      resources :blocks, only: %i[index create destroy]
      resources :reports, only: :create

      # Notifications.
      resources :notifications, only: :index do
        resource :read, only: :create, controller: "notification_reads"
      end
      resource :notification_read_all, only: :create,
             path: "notifications/read_all", controller: "notification_read_alls"
      resource :notification_unread_count, only: :show,
             path: "notifications/unread_count", controller: "notification_unread_counts"
    end
  end

  # All HTML routes are available with an optional locale prefix (e.g. /en, /fr).
  scope "(:locale)", locale: /es|en|fr|de|it|pt/ do
    devise_for :users, skip: :omniauth_callbacks,
                       controllers: { registrations: "users/registrations" }

    resources :categories, only: :show, path: "c"
    resources :listings, only: %i[index show], path: "l" do
      resource :favourite, only: %i[create destroy]
      resources :offers, only: :create
    end
    get "search", to: "listings#index", as: :search

    resource :pc_finder, only: :show, controller: "pc_finders", path: "pc-finder"

    resource :sell_to_us, only: :show, controller: "sell_to_us", path: "sell-to-us"
    resources :buyback_quotes, only: %i[new create show], path: "sell-to-us/quotes"
    resources :buyback_requests, only: %i[index show new create],
                                 path: "sell-to-us/trade-ins"

    resource :trust, only: :show, controller: "trust"
    resources :help_pages, only: %i[index show], path: "help", param: :slug
    resources :contact_messages, only: %i[index create], path: "contact"
    resources :legal_pages, only: %i[index show], path: "legal", param: :kind
    resources :legal_page_versions, only: :index, path: "legal/:kind/versions",
                                    param: :kind, controller: "legal_page_versions"
    resources :newsletter_subscriptions, only: :create, path: "newsletter"
    resources :newsletter_confirmations, only: :show,
                                         path: "newsletter/confirmations", param: :token
    resources :newsletter_unsubscriptions, only: :show,
                                           path: "newsletter/unsubscriptions", param: :token
    resource :cookie_consent, only: :create, controller: "cookie_consents"
    resource :country_preference, only: :update, path: "country",
                                 controller: "country_preferences"

    resources :conversations, only: %i[index show create], path: "inbox" do
      resources :messages, only: :create
    end
    resource :inbox_read, only: :create, path: "inbox/read", controller: "inbox_reads"
    resources :offers, only: :update
    resources :blocks, only: %i[create destroy]
    resources :reports, only: %i[new create]
    resources :stores, only: :show, path: "s", controller: "storefronts", as: :storefronts

    resource :wishlist, only: :show
    resources :stores, only: [] do
      resource :follow, only: %i[create destroy], controller: "follows"
    end
    resources :saved_searches, only: %i[index create update destroy],
                               path: "account/saved_searches"
    resources :notifications, only: :index
    resource :notification_read, only: :create, path: "notifications/read"
    resource :notification_preferences, only: %i[show update], path: "account/notifications"
    resource :email_unsubscribe, only: %i[show create], path: "unsubscribe"

    resource :cart, only: :show
    resources :cart_items, only: %i[create update destroy]
    resource :checkout, only: %i[new show create]

    resources :orders, only: %i[index show] do
      resource :review, only: %i[create update]
      resource :delivery_confirmation, only: :create,
                                       controller: "order_delivery_confirmations"
      resource :cancellation, only: :create,
                              controller: "order_cancellations"
      resource :problem_report, only: :create,
                                controller: "order_problem_reports"
    end
    resources :reviews, only: [] do
      resource :seller_reply, only: :create, controller: "review_seller_replies"
    end

    namespace :account do
      resource :profile, only: %i[show update]
      resource :password, only: :update
      resource :deletion, only: :create
      resources :addresses, only: %i[index new create edit update destroy]
      resource :privacy, only: :show, controller: "privacy"
      resource :data_export, only: %i[create show]
    end

    namespace :sell do
      resource :dashboard, only: :show
      resources :orders, only: %i[index show], path: "sales" do
        resource :shipment, only: :create, controller: "order_shipments"
        resource :cancellation, only: :create, controller: "order_cancellations"
      end
    end

    namespace :store do
      resource :vacation, only: %i[show update]
    end

    resource :store, only: %i[new create edit update]
    resource :payment, only: %i[show create], path: "store/payment",
                       controller: "store/payments", as: :store_payment
    resources :listings, path: "sell", only: %i[index new create edit update destroy],
                         controller: "sell/listings", as: :sell_listings do
      # A state transition is modelled as its own singular resource so the
      # route stays RESTful (POST creates a republish request for one listing).
      resource :republish, only: :create, controller: "sell/listing_republishes"
    end

    # A batch operation is modelled as its own resource so the route stays
    # RESTful (POST creates one bulk archive) instead of a custom action.
    resource :bulk_archive, only: :create, path: "sell/bulk-archive",
                            controller: "sell/bulk_archives"

    namespace :admin do
      resource :dashboard, only: :show, controller: "dashboard"
      resources :listing_reviews, only: %i[index show update], path: "moderation"
      resources :reports, only: %i[index show update]

      resources :listings, only: %i[index show edit update destroy] do
        resource :approval, only: :create, controller: "listing_approvals"
        resource :rejection, only: :create, controller: "listing_rejections"
        resource :archival, only: :create, controller: "listing_archivals"
        resource :restoration, only: :create, controller: "listing_restorations"
        resource :feature, only: :create, controller: "listing_features"
        resource :label, only: :create, controller: "listing_labels"
      end
      resources :listing_bulk_actions, only: :create, path: "listings/bulk"

      resources :users, only: %i[index show edit update] do
        resource :ban, only: %i[create destroy], controller: "user_bans"
        resource :role, only: :create, controller: "user_roles"
        resource :confirmation, only: :create, controller: "user_confirmations"
        resource :confirmation_resend, only: :create, controller: "user_confirmation_resends"
        resource :password_reset, only: :create, controller: "user_password_resets"
        resource :deletion, only: :create, controller: "user_deletions"
      end

      resources :stores, only: %i[index show edit update] do
        resource :verification, only: %i[create destroy], controller: "store_verifications"
        resource :suspension, only: %i[create destroy], controller: "store_suspensions"
        resources :reviews, only: [] do
          resource :visibility, only: %i[create destroy],
                                controller: "store_review_visibilities"
        end
      end

      resources :orders, only: %i[index show] do
        resource :shipment, only: :create, controller: "order_shipments"
        resource :delivery, only: :create, controller: "order_deliveries"
        resource :completion, only: :create, controller: "order_completions"
        resource :cancellation, only: :create, controller: "order_cancellations"
        resource :refund, only: :create, controller: "order_refunds"
        resource :dispute_resolution, only: :create,
                                      controller: "order_dispute_resolutions"
        resources :notes, only: :create, controller: "order_notes"
      end

      resources :payouts, only: :index do
        resource :retry, only: :create, controller: "payout_retries"
      end

      resources :audit_logs, only: :index
      resource :impersonation, only: %i[create destroy], controller: "impersonations"

      resources :categories, only: %i[index new create edit update destroy] do
        resource :category_attribute_positions, only: :update, path: "filters/positions"
        resources :category_attributes, only: %i[index create update destroy], path: "filters"
      end
      resource :category_positions, only: :update

      resources :attribute_definitions, only: %i[index new create edit update destroy], path: "filters" do
        resources :attribute_options, only: %i[create update destroy]
        resources :attribute_option_merges, only: :create
        resource :attribute_option_import, only: :create, controller: "attribute_option_imports"
        resource :attribute_option_positions, only: :update, controller: "attribute_option_positions"
      end

      resources :tags, only: %i[index new create edit update destroy]
      resource :tag_positions, only: :update

      resources :countries, only: %i[index edit update] do
        resources :regions, only: %i[index new create edit update destroy]
        resource :region_import, only: :create, controller: "region_imports"
      end

      resource :settings, only: %i[show update], controller: "settings"
      resources :features, only: %i[index update]

      resources :legal_pages do
        resource :version, only: :create, controller: "legal_page_versions"
        resource :publication, only: :create, controller: "legal_page_publications"
        resource :notification, only: :create, controller: "legal_page_notifications"
        resource :comparison, only: :show, controller: "legal_page_comparisons"
      end

      resources :games, only: %i[index new create edit update destroy]
      resources :gpu_tiers, only: %i[index new create edit update destroy]
      resources :cpu_tiers, only: %i[index new create edit update destroy]

      resources :buyback_prices, only: %i[index new create edit update destroy]
      resources :buyback_price_imports, only: :create
      resources :buyback_requests, only: %i[index show] do
        resources :events, only: :create, controller: "buyback_request_events"
      end

      root to: "dashboard#show"
    end

    root "pages#home"
  end

  # Flipper's UI is only reachable by signed-in admins.
  authenticate :user, ->(user) { user.admin? } do
    mount Flipper::UI.app(Flipper), at: "/admin/flipper"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
