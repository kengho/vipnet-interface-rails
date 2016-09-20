class HwNode < ActiveRecord::Base
  belongs_to :coordinator
  belongs_to :ncc_node
  validates :coordinator, presence: true
  validates :ncc_node, presence: true
  has_many :node_ips, dependent: :destroy

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
      :only => HwNode.props_from_iplirconf + [:ncc_node_id, :coordinator_id, :version_decoded]
    ).gsub("null", "nil")
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
