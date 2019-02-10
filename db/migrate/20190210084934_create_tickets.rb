class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.string :name
      t.string :email
      t.text :query

      t.timestamps
    end
  end
end
