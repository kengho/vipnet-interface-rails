module HashDiffSymUtils
  def decode_changes(changes)
    action = { "+" => :add, "-" => :remove, "~" => :change }[changes[0]]
    target = {}
    target[:vid], target[:field], target[:index] = HashDiffSym.decode_property_path(changes[1])
    if action == :change
      before = changes[2]
      after = changes[3]
    end
    if action == :add || action == :remove
      props = changes[2]
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
          changes_expanded.push([changes[0], id, section])
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
