class RemoveCoordinatorIdFromNodeIps < ActiveRecord::Migration
  def change
    remove_column :node_ips, :coordinator_id, :integer
  end
end
