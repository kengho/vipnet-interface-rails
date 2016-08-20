class RenameTickets < ActiveRecord::Migration
  def change
    rename_column :nodes, :tickets, :ticket
  end
end
