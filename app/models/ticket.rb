class Ticket < ActiveRecord::Base
  belongs_to :ticket_system
  belongs_to :ncc_node
  validates :ticket_system, presence: true
  validates :vid, presence: true
  validates :ticket_id, presence: true
  validates_uniqueness_of :ticket_id, scope: [:vid, :ticket_system]
end
