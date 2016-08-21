class Iplirconf < GarlandBelongs
  belongs_to :coordinator

  def self.props_from_file
    [:ip, :accessip, :version]
  end
end
