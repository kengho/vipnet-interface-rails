class HwNode < AbstractModel
  belongs_to :coordinator
  belongs_to :ncc_node
  validates :coordinator, presence: true
  validates :ncc_node, presence: true
  has_many :node_ips, dependent: :destroy
end
