# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

load Rails.root.join("db/seeds/countries.rb")
load Rails.root.join("db/seeds/regions.rb")
load Rails.root.join("db/seeds/settings.rb")
load Rails.root.join("db/seeds/features.rb")

admin = User.find_or_create_by!(email: "admin@pcmarket.example") do |user|
  user.username = "admin"
  user.password = ENV.fetch("ADMIN_PASSWORD", "ChangeMe123!")
  user.password_confirmation = user.password
  user.role = :admin
  user.first_name = "PCMarket"
  user.last_name = "Admin"
  user.locale = "es"
  user.country_code = "ES"
  user.terms_accepted = "1"
end

admin.update!(role: :admin) unless admin.admin?
admin.confirm unless admin.confirmed?
