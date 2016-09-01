class AccessIp < NodeIp
  validates_uniqueness_of :u32, scope: [:coordinator_id, :node_id]
end
