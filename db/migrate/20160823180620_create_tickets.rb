class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :vid
      t.string :ticket_id
      t.references :ticket_system, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
