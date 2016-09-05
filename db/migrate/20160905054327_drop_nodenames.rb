class DropNodenames < ActiveRecord::Migration
  def change
    drop_table :nodenames
  end
end
