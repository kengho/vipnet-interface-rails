class RenameNodeIdToNccNodeIdInNodeIps < ActiveRecord::Migration
  def change
    rename_column :node_ips, :node_id, :ncc_node_id
  end
end
