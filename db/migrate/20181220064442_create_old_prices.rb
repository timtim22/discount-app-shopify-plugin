class CreateOldPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :old_prices do |t|
      t.references :sale, foreign_key: true
      t.string :product_id
      t.json :variants

      t.timestamps
    end
    add_index :old_prices, :product_id
    add_index :old_prices, [:product_id, :sale_id], :unique => true
  end
end
