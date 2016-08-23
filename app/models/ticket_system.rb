class TicketSystem < ActiveRecord::Base
  validates :url_template, uniqueness: true
  has_many :tickets, dependent: :destroy
end
