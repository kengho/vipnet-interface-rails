class Iplirconf < Garland
  belongs_to :coordinator, foreign_key: "belongs_to_id"
  validates :belongs_to_id, presence: true

  def self.props_from_file
    [:ip, :accessip, :version]
  end
end
