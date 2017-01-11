class Coordinator < ActiveRecord::Base
  include GarlandRails::Extend
  belongs_to :network
  has_many :iplirconfs, dependent: :destroy
  has_many :hw_nodes, dependent: :destroy
  validates :network, presence: true
  validates :vid, presence: true,
                  uniqueness: true,
                  format: {
                    with: NccNode.vid_regexp,
                    message: "vid should be like \"#{NccNode.vid_regexp}\"",
                  }
end
