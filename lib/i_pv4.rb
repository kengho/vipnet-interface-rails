module IPv4
  def ip?(string)
    octets = string.split(".")
    return false unless octets.size == 4
    octets.each do |octet|
      return false unless octet =~ /^\d+$/
      return false unless octet.to_i.between?(0, 255)
    end
    return true
  end

  def cidr(string)
    string =~ /^(.*)\/(.*)$/
    return nil unless Regexp.last_match
    return nil unless Regexp.last_match.size == 3
    probably_ip = Regexp.last_match(1)
    probably_mask = Regexp.last_match(2)
    return nil unless IPv4::ip?(probably_ip)
    return nil unless probably_mask =~ /^\d+$/
    return nil unless probably_mask.to_i.between?(0, 32)
    return [probably_ip, probably_mask.to_i]
  end

  def u32(string)
    return nil unless IPv4::ip?(string)
    octets = string.split(".")
    hex_string = ""
    octets.each { |octet| hex_string << octet.to_i.to_s(16).rjust(2, "0") }
    return hex_string.to_i(16)
  end

  def ip(u32)
    return nil unless u32.class == Fixnum
    return nil unless u32.between?(0, 0xffffffff)
    # http://stackoverflow.com/a/12039844/6376451
    hex_octets = u32.to_s(16).rjust(8, "0").chars.each_slice(2).map(&:join)
    return hex_octets.map { |octet| octet.to_i(16) }.join(".")
  end

  def range(string)
    string =~ /^(.*)-(.*)$/
    return nil unless Regexp.last_match
    return nil unless Regexp.last_match.size == 3
    probably_lower_bound = Regexp.last_match(1)
    return nil unless IPv4::ip?(probably_lower_bound)
    probably_higher_bound = Regexp.last_match(2)
    return nil unless IPv4::ip?(probably_higher_bound)
    return nil unless IPv4::u32(probably_lower_bound) <= IPv4::u32(probably_higher_bound)
    return [probably_lower_bound, probably_higher_bound]
  end

  def u32_bounds(string)
    cidr = IPv4::cidr(string)
    range = IPv4::range(string)
    return nil unless cidr || range
    if cidr
      bitwise_mask = "0xffffffff".to_i(16) >> (32 - cidr[1]) << (32 - cidr[1])
      network_size = 1 << (32 - cidr.last)
      lower_bound = IPv4::u32(cidr.first) & bitwise_mask
      higher_bound = lower_bound + network_size - 1
      return [lower_bound, higher_bound]
    end
    if range
      return [IPv4::u32(range.first), IPv4::u32(range.last)]
    end
  end

  module_function :ip?, :cidr, :u32, :ip, :range, :u32_bounds
end
