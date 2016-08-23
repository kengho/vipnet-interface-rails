class Nodename < GarlandBelongs
  belongs_to :network

  def self.props_from_api
    [:name, :enabled, :category, :abonent_number, :server_number]
  end
end
