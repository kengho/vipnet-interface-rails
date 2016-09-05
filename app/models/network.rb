class Network < ActiveRecord::Base
  has_many :nodenames, dependent: :destroy, foreign_key: "belongs_to_id"
  has_many :coordinators, dependent: :destroy
  has_many :ncc_nodes, dependent: :destroy
  validates :network_vid, presence: true, uniqueness: true
  validates_each :network_vid do |record, attr, value|
    unless value.to_i >= 0x1 && value.to_i <= 0xffff
      record.errors.add(attr, "network_vid should be between 1 and 65535")
    end
  end
end
