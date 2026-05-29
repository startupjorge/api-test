class CreateCustomerAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_accesses do |t|
      t.string :email, null: false
      t.string :note
      t.timestamps
    end
    add_index :customer_accesses, :email, unique: true
  end
end
