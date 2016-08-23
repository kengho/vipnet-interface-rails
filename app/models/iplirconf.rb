class Iplirconf < GarlandBelongs
  belongs_to :coordinator

  def self.props_from_api
    [:ip, :accessip, :version]
  end
end
