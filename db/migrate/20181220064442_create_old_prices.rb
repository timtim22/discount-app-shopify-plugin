class CreateOldPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :old_prices do |t|
      t.references :sale, foreign_key: true
      t.string :variant_id
      t.float :old_price

      t.timestamps
    end
    add_index :old_prices, :variant_id
    add_index :old_prices, [:variant_id, :sale_id], :unique => true
  end
end
