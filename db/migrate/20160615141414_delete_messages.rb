class DeleteMessages < ActiveRecord::Migration
  def change
    remove_column :nodes, :deleted_by_message_id, :integer
    remove_column :nodes, :created_by_message_id, :integer
  end
end
