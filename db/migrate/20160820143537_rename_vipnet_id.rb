class RenameVipnetId < ActiveRecord::Migration
  def change
    rename_column :coordinators, :vipnet_id, :vid
    rename_column :nodes, :vipnet_id, :vid
  end
end
