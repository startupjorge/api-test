class AddInviteTokenToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :invite_token, :text
    add_column :customers, :invite_expires_at, :datetime
  end
end
