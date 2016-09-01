class NodeIp < ActiveRecord::Base
  belongs_to :node
  belongs_to :coordinator
end
