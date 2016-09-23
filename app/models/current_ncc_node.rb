class CurrentNccNode < NccNode
  validates :network, presence: true
  validates :vid, presence: true
end
