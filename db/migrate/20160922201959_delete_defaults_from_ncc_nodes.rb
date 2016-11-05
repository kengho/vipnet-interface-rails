class DeleteDefaultsFromNccNodes < ActiveRecord::Migration
  def change
    change_column_default(:ncc_nodes, :enabled, nil)
    change_column_default(:ncc_nodes, :creation_date_accuracy, nil)
  end
end
