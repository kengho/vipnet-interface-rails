class Iplirconf < ActiveRecord::Base
  belongs_to :coordinator
  validates :coordinator_id,  presence: true,
                              uniqueness: true

  def changed_sections(new_iplirconf)
    # make hashes out of nested hstore
    new_iplirconf_sections = Hash.new
    new_iplirconf.sections.each do |id, section|
      new_iplirconf_sections[id] = eval(section)
    end
    self_sections = Hash.new
    self.sections.each do |id, section|
      self_sections[id] = eval(section)
    end

    changed_sections = Hash.new
    diffs = HashDiff.diff(self_sections, new_iplirconf_sections)
    diffs.each do |diff|
      change = diff[0]
      if change == "+"
        new_value = diff[2]
        # 0x1a0e000a
        if diff[1] =~ /^(\w*)$/
          id = Regexp.last_match(1)
          changed_sections[id] = new_value
        end
      elsif change == "~"
        # 0x1a0e000a.name
        diff[1] =~ /(.*)\.(.*)/
        id = Regexp.last_match(1)
        prop_name = Regexp.last_match(2)
        new_value = diff[3]
        changed_sections[id] = Hash.new unless changed_sections[id]
        changed_sections[id][prop_name.to_sym] = new_value
      elsif change == "-"
        # do nothing
      end
    end
    changed_sections
  end

  def self.props_from_section
    [:ip, :version]
  end
end
