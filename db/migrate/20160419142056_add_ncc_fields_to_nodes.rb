class AddNccFieldsToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :abonent_number, :string
    add_column :nodes, :server_number, :string
  end
end
