class Order < ApplicationRecord

  belongs_to :user, optional: true

  validates :txnid, :amount, :status, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "id",
      "txnid",
      "amount",
      "status",
      "items",
      "user_id",
      "created_at",
      "updated_at"
    ]
  end

  def items_data
    parsed_items = JSON.parse(items.presence || "[]")

    parsed_items.filter_map do |item|
      if item.is_a?(Hash)
        item
      elsif item.is_a?(String)
        parse_legacy_item(item)
      end
    end
  rescue JSON::ParserError
    []
  end

  private

  def parse_legacy_item(item)
    JSON.parse(
      item.gsub("=>", ":").gsub(/\bnil\b/, "null")
    )
  rescue JSON::ParserError
    nil
  end

end