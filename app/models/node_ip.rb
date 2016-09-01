class NodeIp < ActiveRecord::Base
  belongs_to :node
  belongs_to :coordinator
  validates_uniqueness_of :u32, scope: [:coordinator_id, :node_id]
end
