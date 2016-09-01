class CreateIps < ActiveRecord::Migration
  def change
    create_table :node_ips do |t|
      t.references :node, index: true, foreign_key: true
      t.references :coordinator, index: true, foreign_key: true

      t.timestamps null: false
      t.bigint :u32, null: false
    end
  end
end
