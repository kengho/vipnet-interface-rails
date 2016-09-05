class AddHwNodeRefToNodeIps < ActiveRecord::Migration
  def change
    add_reference :node_ips, :hw_node, index: true, foreign_key: true
  end
end
