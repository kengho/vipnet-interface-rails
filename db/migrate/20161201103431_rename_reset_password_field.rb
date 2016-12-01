class RenameResetPasswordField < ActiveRecord::Migration
  def change
    rename_column :users, :reset_password, :reset_password_allowed
  end
end
