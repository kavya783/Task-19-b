# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


AdminUser.find_or_initialize_by(email: "admin@gmail.com").tap do |admin|
  admin.password = "Admin@123"
  admin.password_confirmation = "Admin@123"
  admin.save!
end


# CATEGORIES

categories = [
  "Hair",
  "Baby",
  "Face",
  "Makeup",
  "Body",
  "Perfume",
  "Facewash",
  "Sunscreen",
  "Facemask",
  "Facecream",
  "Serum",
  "Scrub",
  "Moisturizer",
  "Shampoo",
  "Hairoil",
  "Conditioner",
  "Hair Serum",
  "Hairmask",
  "Babywash",
  "Babysoap",
  "Bodylotion",
  "Babyoil",
  "Lipsticks",
  "Kajal",
  "Foundation",
  "Compact",
  "Lipbalm",
  "Concealer",
  "Best Sellers",
  "Flash Sale",
  "Gift Packs",
  "New Launch",
  "Baby Shampoo",
  "Rice",
  "Vitamin C",
  "Ubtan",
  "Rosemary",
  "Beetroot",
  "Onion",
  "Kerala Thali"
]

categories.each do |category_name|
  Category.find_or_create_by!(name: category_name)
end

puts "Imported #{categories.count} categories"

coupons = [
  {
    code: "REDEEM35",
    title: "Get Upto 35% OFF + Extra FREEBIE",
    saving: "Save ₹200 with this offer",
    discount: 200,
    minimum_amount: 0,
    details: "Add any 2 Favorites to the cart & apply the code to get flat 30% OFF + Extra FREEBIE."
  }
]

Coupon.where(code: %w[B3P2 B2G2]).destroy_all

coupons.each do |attributes|
  coupon = Coupon.find_or_initialize_by(code: attributes[:code])
  coupon.assign_attributes(attributes)
  coupon.save!
end

puts "Imported #{coupons.count} coupons"


require "json"

products_file = Rails.root.join("products.json")

if File.exist?(products_file)
  products = JSON.parse(File.read(products_file))

  products.each do |product|
    Product.find_or_create_by!(id: product["id"]) do |p|
      product.each do |key, value|
        next if [ "id", "created_at", "updated_at" ].include?(key)

        p[key] = value
      end
    end
  end

  puts "Imported #{products.count} products"
else
  puts "products.json not found"
end
