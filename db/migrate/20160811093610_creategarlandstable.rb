class Creategarlandstable < ActiveRecord::Migration
  def change
    create_table :garlands do |t|
      t.text :entity
      t.boolean :entity_type
      t.string :type
      t.integer :previous
      t.integer :next
      t.integer :belongs_to_id
      t.string  :belongs_to_type
    end
  end
end
