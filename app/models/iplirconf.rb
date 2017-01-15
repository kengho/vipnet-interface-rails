class Iplirconf < GarlandRails::Base
  belongs_to :coordinator

  def self.props_from_api
    %i[ip accessip version]
  end
end
