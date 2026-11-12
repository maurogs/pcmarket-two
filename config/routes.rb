Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # OmniAuth callbacks must live outside the optional locale scope.
  devise_for :users, only: :omniauth_callbacks,
                     controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # All HTML routes are available with an optional locale prefix (e.g. /en, /fr).
  scope "(:locale)", locale: /es|en|fr|de|it|pt/ do
    devise_for :users, skip: :omniauth_callbacks,
                       controllers: { registrations: "users/registrations" }

    root "pages#home"
  end

  # Flipper's UI is only reachable by signed-in admins.
  authenticate :user, ->(user) { user.admin? } do
    mount Flipper::UI.app(Flipper), at: "/admin/flipper"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
