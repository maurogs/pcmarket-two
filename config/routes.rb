Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OmniAuth callbacks must live outside the optional locale scope.
  devise_for :users, only: :omniauth_callbacks,
                     controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Stripe posts here without a locale prefix and verifies signatures itself.
  post "webhooks/stripe", to: "webhooks/stripe#create", as: :stripe_webhook

  # All HTML routes are available with an optional locale prefix (e.g. /en, /fr).
  scope "(:locale)", locale: /es|en|fr|de|it|pt/ do
    devise_for :users, skip: :omniauth_callbacks,
                       controllers: { registrations: "users/registrations" }

    resources :categories, only: :show, path: "c"
    resources :listings, only: %i[index show], path: "l" do
      resource :favourite, only: %i[create destroy]
    end
    get "search", to: "listings#index", as: :search

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
      resource :delivery_confirmation, only: :create,
                                       controller: "order_delivery_confirmations"
      resource :cancellation, only: :create,
                              controller: "order_cancellations"
      resource :problem_report, only: :create,
                                controller: "order_problem_reports"
    end

    namespace :sell do
      resources :orders, only: %i[index show], path: "sales" do
        resource :shipment, only: :create, controller: "order_shipments"
        resource :cancellation, only: :create, controller: "order_cancellations"
      end
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
