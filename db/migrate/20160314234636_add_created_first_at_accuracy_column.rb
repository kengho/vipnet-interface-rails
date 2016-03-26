class AddCreatedFirstAtAccuracyColumn < ActiveRecord::Migration
  def change
    add_column :nodes, :created_first_at_accuracy, :boolean, :default => true
  end
end
