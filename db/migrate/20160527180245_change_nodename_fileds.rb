class ChangeNodenameFileds < ActiveRecord::Migration
  def change
    rename_column :nodenames, :content, :records
    add_column :nodenames, :content, :string
  end
end
