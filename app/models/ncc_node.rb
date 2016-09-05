class NccNode < AbstractModel
  belongs_to :network
  validates :network, presence: true
  has_many :hw_nodes, dependent: :destroy

  def self.vid_regexp
    /\A0x[0-9a-f]{8}\z/
  end

  validates :vid,
            presence: true,
            format: { with: Node.vid_regexp, message: "vid should be like \"#{NccNode.vid_regexp}\"" }
end
