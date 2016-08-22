class DeleteCreatedFirstAtFromNodes < ActiveRecord::Migration
  def change
    remove_column :nodes, :created_first_at, :datetime
  end
end
