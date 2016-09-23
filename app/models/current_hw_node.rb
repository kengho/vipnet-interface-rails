class CurrentHwNode < HwNode
  validates :coordinator, presence: true
  validates :ncc_node, presence: true
end
