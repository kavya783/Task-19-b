class AddMamaCashUsedToOrders < ActiveRecord::Migration[8.1]
def change
  add_column :orders, :mama_cash_used,
             :decimal,
             precision: 10,
             scale: 2,
             null: false,
             default: 0
end
end
