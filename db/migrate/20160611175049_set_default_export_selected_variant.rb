class SetDefaultExportSelectedVariant < ActiveRecord::Migration
  def change
    Settings.new(var: "export_selected_variant", value: "id_space_name_newline").save!
  end
end
