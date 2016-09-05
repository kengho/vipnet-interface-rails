class RemoveNccNodeIdFromNodeIps < ActiveRecord::Migration
  def change
    remove_column :node_ips, :ncc_node_id, :integer
  end
end
