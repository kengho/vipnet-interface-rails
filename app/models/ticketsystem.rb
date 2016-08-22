TicketSystem < ActiveRecord::Base
  validates :url_template, uniqueness: true
end
