class RenameAdministratorRole < ActiveRecord::Migration[5.0]
  def change
    User.find_each do |user|
      user.update_attributes(role: "admin") if user.role == "administrator"
    end
  end
end
