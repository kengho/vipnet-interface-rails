class CreateHwNodesTable < ActiveRecord::Migration
  def change
    create_table :hw_nodes do |t|
      t.string :accessip
      t.string :version
      t.string :version_decoded
      t.timestamps
    end
  end
end
