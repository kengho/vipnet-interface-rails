class Garland < ActiveRecord::Base
  validates :entity, presence: true
  validates_inclusion_of :entity_type, in: [true, false]

  SNAPSHOT = false
  DIFF = true
end
