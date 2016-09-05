class AddCoordinatorRefToHwNodes < ActiveRecord::Migration
  def change
    add_reference :hw_nodes, :coordinator, index: true, foreign_key: true
  end
end
