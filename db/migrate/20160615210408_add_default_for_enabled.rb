class AddDefaultForEnabled < ActiveRecord::Migration
  def change
    change_column :nodes, :enabled, :boolean, :default => true
  end
end
