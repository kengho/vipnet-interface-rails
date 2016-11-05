class CurrentNccNode < NccNode
  validates :network, presence: true
  validates :vid, presence: true
  validates_uniqueness_of :vid
end
