class AddDescendantIdToNccNodes < ActiveRecord::Migration
  def change
    add_column :ncc_nodes, :descendant_id, :integer
  end
end
