class Garland < ActiveRecord::Base
  DIFF = true
  SNAPSHOT = false
  NEXT_ID_PENDING = 0

  validates :entity, presence: true
  validates_inclusion_of :entity_type, in: [DIFF, SNAPSHOT]
  # for given parent object, described by "belongs_to_id" and "belongs_to_type",
  # there are only one record of each type which is on top of the stack
  validates_uniqueness_of :type, scope: [
    :belongs_to_id,
    :belongs_to_type,
    :next,
  ], conditions: -> { where(next: nil) }

  def self.push(args)
    if args.class != Hash
      return nil
    end
    if args[:hash]
      hash = args[:hash]
      belongs_to = args[:belongs_to]
      if belongs_to
        belongs_to_id = args[:belongs_to].id
        belongs_to_type = table_type(args[:belongs_to])
      end
      partial = args[:partial]
    else
      hash = args
      belongs_to = nil
      belongs_to_id = nil
      belongs_to_type = nil
      partial = nil
    end

    thread = self.thread(belongs_to)
    if thread.size == 0
      new_element = self.new(
        entity: hash.to_s,
        entity_type: SNAPSHOT,
        belongs_to_id: belongs_to_id,
        belongs_to_type: belongs_to_type
      )
      if new_element.save
        if partial
          diff = HashDiffSym.diff({}, hash[partial])
        else
          diff = HashDiffSym.diff({}, hash)
        end
        return diff, new_element.created_at
      else
        return nil
      end
    else
      snapshot = self.snapshot(belongs_to)
      last_element = thread.find_by(next: nil)
      # can't assign next id until new_element is saved
      last_element.next = NEXT_ID_PENDING
      unless last_element.save
        return nil
      end
      diff = HashDiffSym.diff(eval(snapshot.entity), hash)
      if diff == []
        return []
      else
        new_element = self.new(
          entity: diff.to_s,
          entity_type: DIFF,
          previous: last_element.id,
          belongs_to_id: belongs_to_id,
          belongs_to_type: belongs_to_type
        )

        if new_element.save
          last_element.next = new_element.id
          if last_element.save
            if partial
              return_diff = HashDiffSym.diff(eval(snapshot.entity)[partial], hash[partial])
            else
              return_diff = diff
            end
            return return_diff, new_element.created_at
          else
            new_element.destroy
            return nil
          end
        else
          return nil
        end
      end
    end
  end

  def self.snapshot(belongs_to = nil)
    thread = self.thread(belongs_to)
    last_snapshot = thread.find_by(next: nil)
    if last_snapshot == nil
      Rails.logger.error(
        "Requested for snapshot, but either Garland has no records "\
        "or there is broken stack top for thread with type = '#{self.name}' and belongs_to = '#{belongs_to}'"
      )
      return
    end

    until last_snapshot.entity_type == SNAPSHOT do
      last_snapshot = thread.find_by_id(last_snapshot.previous)
    end

    snapshot = last_snapshot
    snapshot_hash = eval(snapshot.entity)
    until snapshot.next == nil do
      next_thread = thread.find_by_id(snapshot.next)
      snapshot_hash = HashDiffSym.patch!(snapshot_hash, eval(next_thread.entity))
      snapshot = next_thread
    end

    self.new(entity: snapshot_hash.to_s, entity_type: SNAPSHOT)
  end

  def self.any?(belongs_to)
    self.thread(belongs_to).any?
  end

  def self.decode_changes(changes)
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

  private
    def self.thread(belongs_to)
      if belongs_to == nil
        return self.where("belongs_to_id is null AND belongs_to_type is null")
      else
        return self.where("belongs_to_id = ? AND belongs_to_type = ?", belongs_to.id, table_type(belongs_to))
      end
    end

    def self.table_type(record)
      record.class.name
    end
end
