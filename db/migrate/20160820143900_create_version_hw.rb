class CreateVersionHw < ActiveRecord::Migration
  def change
    rename_column :nodes, :version, :version_hw
    add_column :nodes, :version, :hstore, :default => {}
  end
end
