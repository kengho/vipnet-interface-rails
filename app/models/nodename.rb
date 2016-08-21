class Nodename < Garland
  belongs_to :network, foreign_key: "belongs_to_id"
  validates :network, presence: true
  validates_inclusion_of :belongs_to_type, in: ["Network"]

  def self.props_from_file
    [:name, :enabled, :category, :abonent_number, :server_number]
  end
end
