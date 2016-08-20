class Garland < AbstractModel
  validates :entity, presence: true
  validates_inclusion_of :entity_type, in: [true, false]
  # for given parent object, described by "belongs_to_id" and "belongs_to_type",
  # there are only one record of each type which is on top of the stack
  validates_uniqueness_of :type, scope: [:belongs_to_id, :belongs_to_type, :next], conditions: -> { where(next: nil) }

  SNAPSHOT = false
  DIFF = true
  NEXT_ID_PENDING = 0

  def self.push(args)
    if args.class != Hash
      return false
    end
    if args[:hash]
      h = args[:hash]
      b_to = args[:belongs_to]
      b_to_id = args[:belongs_to].id
      b_to_type = table_type(args[:belongs_to])
    else
      h = args
      b_to = nil
      b_to_id = nil
      b_to_type = nil
    end

    thread = self.thread(b_to)
    if thread.size == 0
      n = self.new(entity: h.to_s, entity_type: SNAPSHOT, belongs_to_id: b_to_id, belongs_to_type: b_to_type)
      if n.save
        return HashDiffSym.diff({}, h)
      else
        return false
      end
    else
      s = self.snapshot(b_to)
      last_e = thread.find_by(next: nil)
      # can't assign next id until new record (n) is saved
      last_e.next = NEXT_ID_PENDING
      unless last_e.save
        return false
      end
      d = HashDiffSym.diff(eval(s.entity), h)
      n = self.new(entity: d.to_s, entity_type: DIFF, previous: last_e.id, belongs_to_id: b_to_id, belongs_to_type: b_to_type)

      if n.save
        last_e.next = n.id
        if last_e.save
          return d
        else
          n.destroy
          return false
        end
      else
        return false
      end
    end
  end

  def self.snapshot(b_to = nil)
    thread = self.thread(b_to)
    last_s = thread.find_by(next: nil)
    if last_s == nil
      Rails.logger.error(
        "Requested for snapshot, but either Garland has no records "\
        "or there is broken stack top for thread with type = '#{self.name}' and belongs_to = '#{b_to}'"
      )
      return
    end
    until last_s.entity_type == SNAPSHOT do
      last_s = thread.find_by_id(last_s.previous)
    end
    s = last_s
    s_h = eval(s.entity)
    until s.next == nil do
      n = thread.find_by_id(s.next)
      s_h = HashDiffSym.patch!(s_h, eval(n.entity))
      s = n
    end
    self.new(entity: s_h.to_s, entity_type: SNAPSHOT)
  end

  def self.any?(b_to)
    self.thread(b_to).any?
  end

  private
    def self.thread(b_to)
      if b_to == nil
        return self.where("belongs_to_id is null AND belongs_to_type is null")
      else
        return self.where("belongs_to_id = ? AND belongs_to_type = ?", b_to.id, table_type(b_to))
      end
    end

    def self.table_type(record)
      record.class.name
    end
end
