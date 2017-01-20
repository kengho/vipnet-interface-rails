class UpgradeGarlandV0ToV1 < ActiveRecord::Migration[5.0]
  def change
    rename_column :garlands, :next, :next_id
    rename_column :garlands, :previous, :previous_id
  end
end
