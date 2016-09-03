class AddTypes < ActiveRecord::Migration
  def change
    add_column :nodes, :type, :string
    add_column :node_ips, :type, :string
  end
end
