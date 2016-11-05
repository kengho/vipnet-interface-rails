class AddTimestampsToGarland < ActiveRecord::Migration
  def change
    add_column :garlands, :created_at, :datetime, null: false
    add_column :garlands, :updated_at, :datetime, null: false
  end
end
