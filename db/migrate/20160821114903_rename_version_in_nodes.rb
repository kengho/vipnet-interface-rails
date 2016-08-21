class RenameVersionInNodes < ActiveRecord::Migration
  def change
    rename_column :nodes, :version_hw, :version_decoded
  end
end
