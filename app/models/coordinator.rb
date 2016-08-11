class Coordinator < ActiveRecord::Base
#   belongs_to :network
#   has_many :iplirconfs, dependent: :destroy
#   validates :network_id, presence: true
#   validates :vipnet_id, presence: true,
#                         uniqueness: true,
#                         format: { with: /\A0x[0-9a-f]{8}\z/, message: "vipnet_id should be like \"0x1a0e0100\"" }
#
end
