class RenameTicketsystemTable < ActiveRecord::Migration
  def change
    rename_table :ticketsystems, :ticket_systems
  end
end
