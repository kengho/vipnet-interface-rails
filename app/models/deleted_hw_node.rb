class DeletedHwNode < HwNode
  validates :coordinator, presence: true
  validates :ncc_node, presence: true, uniqueness: { scope: [:coordinator] }
end
