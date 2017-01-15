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
      /^4\.2.*/ => "4.2",
      /^4\.3.*/ => "4.3",
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
    json = self.to_json(
      include: {
        node_ips: {
          only: :u32,
        },
      },
      only: [
        :type,
        :ncc_node_id,
        :coordinator_id,
        :descendant_id,
        :creation_date,
        :accessip,
        :version,
        :version_decoded,
      ],
    ).gsub("null", "nil")
    json = eval(json)
    tmp = json.clone
    json.each do |key, value|
      if key == :coordinator_id
        coordinator = Coordinator.find_by(id: value)
        tmp[:coord_vid] = coordinator.vid if coordinator
      elsif key == :ncc_node_id
        ncc_node = NccNode.find_by(id: value)
        tmp[:ncc_node_vid] = ncc_node.vid if ncc_node
      elsif key == :descendant_id
        descendant = HwNode.find_by(id: value)
        if descendant
          ncc_node = descendant.ncc_node
          if ncc_node
            tmp[:descendant_coord_vid] = descendant.coordinator.vid
            tmp[:descendant_vid] = ncc_node.vid
          end
        end
      end
    end
    tmp.reject! do |key, value|
      [nil, []].include?(value) ||
      [:coordinator_id, :ncc_node_id, :descendant_id].include?(key) ||
      false
    end

    tmp.to_json
  end

  def self.props_from_iplirconf
    %i[
      accessip
      version
      version_decoded
    ]
  end

  private
    def update_version_decoded
      self.version_decoded = HwNode.decode_version(self.version)
    end
end
