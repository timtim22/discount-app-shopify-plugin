class AddActivationToShop < ActiveRecord::Migration[5.2]
  def change
  	add_column :shops, :activated, :boolean, default: false
  end
end
