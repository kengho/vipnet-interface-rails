class RemoveNullValidationForCreationDateInHwNodes < ActiveRecord::Migration
  def change
    change_column_null(:hw_nodes, :creation_date, true)
  end
end
