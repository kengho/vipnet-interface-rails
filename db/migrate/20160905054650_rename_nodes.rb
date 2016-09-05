class RenameNodes < ActiveRecord::Migration
  def change
    rename_table :nodes, :ncc_nodes
  end
end
