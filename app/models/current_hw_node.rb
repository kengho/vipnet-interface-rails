class CurrentHwNode < HwNode
  validates :coordinator, presence: true
  validates :ncc_node, presence: true
  validates_uniqueness_of :ncc_node, scope: [:coordinator]
end
