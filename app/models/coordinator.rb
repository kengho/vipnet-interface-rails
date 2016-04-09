class Coordinator < ActiveRecord::Base
  belongs_to :network
  has_many :iplirconfs, dependent: :destroy
  validates :network_id, presence: true
  validates :vipnet_id, presence: true,
                        uniqueness: true
end
