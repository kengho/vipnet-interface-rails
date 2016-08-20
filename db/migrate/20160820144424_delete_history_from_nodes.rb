class DeleteHistoryFromNodes < ActiveRecord::Migration
  def change
    remove_column :nodes, :history, :boolean
  end
end
