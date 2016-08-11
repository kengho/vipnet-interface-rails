class Creategarlandstable < ActiveRecord::Migration
  def change
    create_table :garlands do |t|
      t.string :name
      t.text :entity
      t.boolean :entity_type
      t.string :type
      t.integer :next
      t.integer :previous
      t.integer :belongs_to_id
    end
  end
end
