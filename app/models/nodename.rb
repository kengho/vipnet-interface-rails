class Nodename < Garland
  belongs_to :network, foreign_key: "belongs_to_id"
  validates :belongs_to_id, presence: true

  def self.props_from_file
    [:name, :enabled, :category, :abonent_number, :server_number]
  end
end
