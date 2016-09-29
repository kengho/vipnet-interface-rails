class AddCreationDateToHwNodes < ActiveRecord::Migration
  def change
    add_column :hw_nodes, :creation_date, :datetime, null: false
  end
end
