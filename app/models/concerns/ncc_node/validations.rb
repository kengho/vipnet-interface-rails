require "active_support/concern"

module NccNode::Validations
  extend ActiveSupport::Concern

  included do
    validates :network, presence: true
    validates :vid, presence: true, uniqueness: true
  end
end
