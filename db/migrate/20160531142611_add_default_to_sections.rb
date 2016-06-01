class AddDefaultToSections < ActiveRecord::Migration
  def change
    change_column :iplirconfs, :sections, :hstore, :default => {}
  end
end
