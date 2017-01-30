require "active_support/concern"

module HwNode::Validations
  extend ActiveSupport::Concern

  included do
    validates :coordinator, presence: true
    validates :ncc_node, presence: true, uniqueness: { scope: [:coordinator] }
  end
end
