class Network < ActiveRecord::Base
  has_many :nodenames, dependent: :destroy
  has_many :coordinators, dependent: :destroy
  has_many :nodes, dependent: :destroy
  validates :vipnet_network_id, presence: true,
                                uniqueness: true,
                                format: { with: /\A[0-9]{4}\z/, message: "vipnet_network_id should be like \"6670\"" }
end
