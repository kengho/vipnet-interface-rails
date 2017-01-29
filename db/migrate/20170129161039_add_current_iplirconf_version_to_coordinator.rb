class AddCurrentIplirconfVersionToCoordinator < ActiveRecord::Migration[5.0]
  def change
    add_column :coordinators, :current_iplirconf_version, :string
  end
end
