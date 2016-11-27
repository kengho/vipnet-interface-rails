class AddRestorePasswordFieldToUser < ActiveRecord::Migration
  def change
    add_column :users, :reset_password, :boolean
  end
end
