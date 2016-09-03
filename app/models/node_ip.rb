class NodeIp < AbstractModel
  belongs_to :node
  belongs_to :coordinator
  validates_uniqueness_of :u32, scope: [:coordinator_id, :node_id, :type]
  validates :node, presence: true
  validates :coordinator, presence: true
  validates_each :u32 do |record, attr, value|
    unless value.to_i >= 0x0 && value.to_i <= 0xffffffff
      record.errors.add(attr, "u32 should be between 0 and 4294967295")
    end
  end

  MODELS = {
    :ip => "Ip",
    :accessip => "Accessip",
  }

  def self.create_ips(coordinator, node, props)
    props.each do |prop, values|
      if MODELS[prop]
        # ip is array, accessip is string
        Array(values).each do |value|
          if IPv4::ip?(value)
            Object.const_get(MODELS[prop]).create!(
              node: node,
              coordinator: coordinator,
              u32: IPv4::u32(value),
            )
          end
        end
      end
    end
  end

  def self.change_ip(coordinator, node, field, before, after)
    if MODELS[field] && IPv4::ip?(after)
      ip = Object.const_get(MODELS[field]).find_by(
        node: node,
        coordinator: coordinator,
        u32: IPv4::u32(before)
      )
      if ip
        ip.u32 = IPv4::u32(after)
        ip.save!
      end
    end
  end

  def self.add_ip(coordinator, node, field, ip)
    if MODELS[field] && IPv4::ip?(ip)
      Object.const_get(MODELS[field]).create!(
        node: node,
        coordinator: coordinator,
        u32: IPv4::u32(ip),
      )
    end
  end

  def self.remove_ip(coordinator, node, field, ip)
    if MODELS[field] && IPv4::ip?(ip)
      ip = Object.const_get(MODELS[field]).find_by(
        node: node,
        coordinator: coordinator,
        u32: IPv4::u32(ip)
      )
      ip.destroy if ip
    end
  end
end
