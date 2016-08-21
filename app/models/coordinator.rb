class Coordinator < ActiveRecord::Base
  belongs_to :network
  has_many :iplirconfs, dependent: :destroy, foreign_key: "belongs_to_id"
  validates :network_id, presence: true
  validates :vid, presence: true,
                  uniqueness: true,
                  format: { with: /\A0x[0-9a-f]{8}\z/, message: "vid should be like \"0x1a0e0100\"" }
end
