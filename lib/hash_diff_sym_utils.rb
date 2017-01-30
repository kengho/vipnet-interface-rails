module HashDiffSymUtils
  def decode_changes(changes)
    action = { "+" => :add, "-" => :remove, "~" => :change }[changes.first]
    target = {}
    target[:vid], target[:field], target[:index] =
      HashDiffSym.decode_property_path(changes[1])
    if action == :change
      before = changes[2]
      after = changes[3]
    end
    props = changes[2] if action == :add || action == :remove

    if target[:field] == :ip
      ip_format_v4 = props =~ /(?<ip>.+),\s(?<accessip>.+)/
      props = Regexp.last_match(:ip) if ip_format_v4
    end

    [action, target, props, before, after]
  end

  def expand_changes(changes)
    changes_expanded = []
    if changes[1] =~ /:id(\.)?(?<vid>.*)/
      # ["+", ":id", {"0x1a0e000a"=>{:name=>"coordinator1", ...
      # =>
      # [["+", "0x1a0e000a", {:name=>"coordinator1"], ...
      if Regexp.last_match(:vid).empty?
        changes[2].each do |id, section|
          changes_expanded.push([changes.first, id, section])
        end
      # ["+", ":id.0x1a0e000d", {:name=>"coordinator2", :filterdefault=>"pass", ...
      # =>
      # ["+", "0x1a0e000d", {:name=>"coordinator2", :filterdefault=>"pass", ...
      else
        changes[1] = Regexp.last_match(:vid)
        changes_expanded.push(changes)
      end
    end

    changes_expanded
  end

  module_function :decode_changes, :expand_changes
end
