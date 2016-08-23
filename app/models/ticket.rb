class Ticket < ActiveRecord::Base
  belongs_to :ticket_system
  validates :ticket_system, presence: true
  validates :vid, presence: true
  validates :ticket_id, presence: true
  validates_uniqueness_of :ticket_id, scope: [:vid, :ticket_system]

  def self.props_from_api
    [:ticket]
  end
end
