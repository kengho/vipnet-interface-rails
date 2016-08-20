class RenameVipnetNetworkId < ActiveRecord::Migration
  def change
    rename_column :networks, :vipnet_network_id, :network_vid
  end
end
