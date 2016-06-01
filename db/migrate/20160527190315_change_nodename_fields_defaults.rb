class ChangeNodenameFieldsDefaults < ActiveRecord::Migration
  def change
    change_column :nodenames, :records, :hstore, :default => {}
  end
end
