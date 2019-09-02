class AddCurrencyToShop < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :currency, :string
  end
end
