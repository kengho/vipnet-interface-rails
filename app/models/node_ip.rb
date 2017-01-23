class NodeIp < ActiveRecord::Base
  belongs_to :hw_node
  validates :u32, uniqueness: { scope: [:hw_node_id, :type] }
  validates :hw_node, presence: true
  validates_each :u32 do |record, attr, value|
    unless value.to_i.between?(0, 0xffffffff)
      record.errors.add(attr, "u32 should be between 0 and 4294967295")
    end
  end
end
