class AddTicketsToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :tickets, :hstore, :default => {}
  end
end

