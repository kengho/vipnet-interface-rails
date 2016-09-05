class DeleteUnrelatedFieldsFromNccNodes < ActiveRecord::Migration
  def change
    remove_column :ncc_nodes, :ip, :hstore
    remove_column :ncc_nodes, :version, :hstore
    remove_column :ncc_nodes, :version_decoded, :hstore
    remove_column :ncc_nodes, :ticket, :hstore
    remove_column :ncc_nodes, :accessip, :hstore
  end
end
