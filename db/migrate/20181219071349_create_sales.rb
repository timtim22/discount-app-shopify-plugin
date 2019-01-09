class CreateSales < ActiveRecord::Migration[5.2]
  def change
    create_table :sales do |t|
      t.references :shop
      t.string :title, null: false
      t.integer :sale_target, default: 0
      t.float :amount
      t.integer :sale_type, default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 1
      t.boolean :scheduled, default: false

      t.timestamps
    end
  end
end
