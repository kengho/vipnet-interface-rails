class AddNccNodeRefToTickets < ActiveRecord::Migration
  def change
    add_reference :tickets, :ncc_node, index: true, foreign_key: true
  end
end
