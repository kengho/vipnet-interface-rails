class HwNode < ActiveRecord::Base
  belongs_to :coordinator
  belongs_to :ncc_node
  has_many :node_ips, dependent: :destroy
  has_many :ascendants, dependent: :destroy,
           class_name: "HwNode",
           foreign_key:"descendant_id"
  belongs_to :descendant,
             class_name: "HwNode",
             foreign_key:"descendant_id"
  validates_presence_of :descendant, unless: :type?

  before_save :update_version_decoded, if: :version_changed?

  def self.decode_version(version)
    substitution_list = {
      /^3\.0\-.*/ => "3.1",
      /^3\.2\-.*/ => "3.2",
      /^0\.3\-2$/ => "3.2 (11.19855)",
      /^4\..*/ => "4",
    }
    substitution_list.each do |regexp, outcome|
      return outcome if version =~ regexp
    end
    nil
  end

  def self.to_json_hw
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_hw))
    end
    result.to_json.gsub("null", "nil")
  end

  def to_json_hw
    self.to_json(
      :only => HwNode.props_from_iplirconf + [:ncc_node_id, :coordinator_id, :version_decoded, :type]
    ).gsub("null", "nil")
  end

  def self.to_json_ascendants
    result = []
    self.all.each do |e|
      to_json_ascendants = e.to_json_ascendants
      result.push(eval(to_json_ascendants)) if to_json_ascendants
    end
    result.to_json
  end

  def to_json_ascendants
    descendant = self.descendant
    if descendant
      attributes = self.attributes.reject do |attribute, value|
        [
          "id",
          "created_at",
          "updated_at",
          "ncc_node_id",
          "coordinator_id",
          "descendant_id"
        ].include?(attribute) ||
        value == nil ||
        false
      end
      attributes.merge!({
        descendant_type: descendant.type,
        descendant_coord_vid: descendant.coordinator.vid,
        descendant_vid: descendant.ncc_node.vid,
      })
      attributes.to_json
    end
  end

  def self.props_from_iplirconf
    [
      :accessip,
      :version,
    ]
  end

  private
    def update_version_decoded
      self.version_decoded = HwNode.decode_version(self.version)
    end
end
