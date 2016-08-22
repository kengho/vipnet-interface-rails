class CreateTicketsystemTable < ActiveRecord::Migration
  def change
    create_table :ticketsystems do |t|
      t.string "url_template"
    end
  end
end
