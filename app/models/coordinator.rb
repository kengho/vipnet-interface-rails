class Coordinator < ActiveRecord::Base
  include GarlandRails::Extend
  belongs_to :network
  has_many :iplirconfs, dependent: :destroy
  has_many :hw_nodes, dependent: :destroy
  validates :network, presence: true
  validates :vid, vid: true, presence: true, uniqueness: true
end
