class Network < ActiveRecord::Base
  has_many :nodenames, dependent: :destroy, foreign_key: "belongs_to_id"
  has_many :coordinators, dependent: :destroy
  has_many :nodes, dependent: :destroy
  validates :network_vid, presence: true,
                          uniqueness: true,
                          format: { with: /\A[0-9]{4}\z/, message: "network_vid should be like \"6670\"" }
end
