class AddDescendantIdToHwNodes < ActiveRecord::Migration
  def change
    add_column :hw_nodes, :descendant_id, :integer
  end
end
