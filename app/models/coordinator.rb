class Coordinator < ActiveRecord::Base
  belongs_to :network
  has_many :iplirconfs, dependent: :destroy, foreign_key: "belongs_to_id"
  has_many :hw_nodes, dependent: :destroy
  validates :network, presence: true
  validates :vid, presence: true,
                  uniqueness: true,
                  format: { with: Node.vid_regexp, message: "vid should be like \"#{Node.vid_regexp}\"" }
end
