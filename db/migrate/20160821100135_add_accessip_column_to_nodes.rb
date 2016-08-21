class AddAccessipColumnToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :accessip, :hstore, :default => {}
  end
end
