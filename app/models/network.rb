class Network < ActiveRecord::Base
  has_many :messages, dependent: :destroy
  has_many :nodenames, dependent: :destroy
  has_many :coordinators, dependent: :destroy
  has_many :nodes, dependent: :destroy
  validates :vipnet_network_id, presence: true,
                                uniqueness: true

  def self.find_or_create_network(vipnet_network_id)
    networks = Network.where("vipnet_network_id = '#{vipnet_network_id}'")
    if networks.size == 0
      network = Network.new(vipnet_network_id: vipnet_network_id)
      unless network.save
        Rails.logger.error("Unable to save network '#{vipnet_network_id}'")
        return false
      end
    elsif networks.size == 1
      network = networks.first
    end
    network
  end

end
