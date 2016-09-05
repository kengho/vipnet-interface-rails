class AddTypeToHwNodes < ActiveRecord::Migration
  def change
    add_column :hw_nodes, :type, :string
  end
end
