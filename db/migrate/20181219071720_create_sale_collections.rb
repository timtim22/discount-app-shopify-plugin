class CreateSaleCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :sale_collections do |t|
      t.references :sale, foreign_key: true
      t.string :collection_id

      t.timestamps
    end
  end
end
