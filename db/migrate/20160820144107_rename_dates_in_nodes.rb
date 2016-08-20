class RenameDatesInNodes < ActiveRecord::Migration
  def change
    rename_column :nodes, :deleted_at, :deletion_date
    rename_column :nodes, :created_first_at_accuracy, :creation_date_accuracy
    add_column :nodes, :creation_date, :datetime
  end
end
