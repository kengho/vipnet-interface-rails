class HwNode < ActiveRecord::Base
  belongs_to :coordinator
  belongs_to :ncc_node
  has_many :node_ips, dependent: :destroy
  has_many :ascendants,
           dependent: :destroy,
           class_name: "HwNode",
           foreign_key: "descendant_id"
  belongs_to :descendant,
             class_name: "HwNode",
             foreign_key: "descendant_id"
  validates :descendant, presence: { unless: :type? }

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

  def self.create_with_ips(props)
    hw_node_props = props.reject { |prop, _| prop == :ip }
    hw_node = CurrentHwNode.create!(hw_node_props)
    hw_node.create_ips(props[:ip])
  end

  def update_with_ips(props)
    hw_node_props = props.reject { |prop, _| prop == :ip }
    update_attributes(hw_node_props)
    create_ips(props[:ip])
  end

  def find_or_create_accendant(ascendants_ids, creation_date)
    accendant = HwNode
                  .where(id: ascendants_ids)
                  .find_by(descendant: self)

    return accendant if accendant

    accendant = HwNode.create!(
      descendant: self,
      creation_date: creation_date,
    )
    ascendants_ids.push(accendant.id)

    accendant
  end

  def delete_ip(ip, ascendant)
    node_ip = NodeIp.find_by(
      hw_node: self,
      u32: IPv4.u32(ip),
    )
    return unless node_ip

    node_ip.update_attributes(hw_node_id: ascendant.id)
  end

  def undelete(new_props, creation_date)
    # At first, we are trying to figure out, was there such section in past or not?
    # Maybe connection between node and coordinator was deleted and added again?
    # If so, HwNode should go from "DeletedHwNode" to "CurrentHwNode" and it's attributes should be upgraded.
    # Also, old attributes of "deleted_hw_node" should be saved in ascendant.
    # (At this point we don't save HwNode's status ("Deleted" or "Current") in ascendant.)
    #
    # Create accendant.
    accendant_props = attributes
    accendant_props.reject! do |prop, _|
      !HwNode.props_from_iplirconf.include?(prop.to_sym)
    end

    accendant_props[:descendant] = self
    accendant_props[:creation_date] = creation_date
    accendant = HwNode.create!(accendant_props)

    # Move ips to accendant.
    node_ips.each do |node_ip|
      node_ip.update_attributes(hw_node_id: accendant.id)
    end

    # Prepare new props.
    #
    # If some prop was deleted, "new_section_props" will lack of it,
    # thus "update_attributes" will leave this prop as it was before,
    # but we want it to become "nil".
    # ["prop1", "prop2", "prop3"]
    #  =>
    # { "prop1" => nil, "prop2" => nil, "prop3" => nil }
    nil_props_array = HwNode
                        .props_from_iplirconf
                        .flat_map { |x| [x, nil] }
    deleted_hw_node_props = Hash[*nil_props_array]
    deleted_hw_node_props.merge!(new_props)
    deleted_hw_node_props[:type] = "CurrentHwNode"

    # Update self.
    update_with_ips(deleted_hw_node_props)

    accendant
  end

  def create_ips(ips)
    return unless ips
    ips.each do |ip|
      next unless IPv4.ip?(ip)
      NodeIp.create!(hw_node: self, u32: IPv4.u32(ip))
    end
  end

  def self.to_json_hw
    result = []
    all.find_each do |e|
      result.push(eval(e.to_json_hw))
    end

    result.to_json.gsub("null", "nil")
  end

  def to_json_hw
    json = to_json(
      include: {
        node_ips: {
          only: :u32,
        },
      },
      only: %i(
        type
        ncc_node_id
        coordinator_id
        descendant_id
        creation_date
        accessip
        version
        version_decoded
      ),
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
        %i(coordinator_id ncc_node_id descendant_id).include?(key)
    end

    tmp.to_json
  end

  def self.props_from_iplirconf
    %i(
      ip
      accessip
      version
      version_decoded
    )
  end

  private

    def update_version_decoded
      self.version_decoded = HwNode.decode_version(version)
    end
end
