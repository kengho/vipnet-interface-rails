class AddNccNodeRefToHwNodes < ActiveRecord::Migration
  def change
    add_reference :hw_nodes, :ncc_node, index: true, foreign_key: true
  end
end
