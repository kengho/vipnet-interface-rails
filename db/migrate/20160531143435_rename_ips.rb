class RenameIps < ActiveRecord::Migration
  def change
    rename_column :nodes, :ips, :ip
    rename_column :nodes, :vipnet_version, :version
  end
end
