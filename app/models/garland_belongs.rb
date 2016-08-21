class GarlandBelongs < Garland
  def self.belongs_to(type)
    super type, foreign_key: "belongs_to_id"
    validates type, presence: true
    validates_inclusion_of :belongs_to_type, in: ["#{type.capitalize}"]
  end
end
