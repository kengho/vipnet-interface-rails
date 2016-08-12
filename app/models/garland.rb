class Garland < ActiveRecord::Base
  validates :entity, presence: true
  validates_inclusion_of :entity_type, in: [true, false]
  validates_uniqueness_of :type, scope: [:belongs_to_id, :next], conditions: -> { where(next: nil) }

  SNAPSHOT = false
  DIFF = true
  NEXT_ID_PENDING = -1

  def self.push(args)

    if args.class != Hash
      return false
    end
    if args[:hash]
      h = args[:hash]
      b_to = args[:belongs_to]
      b_to_id = b_to.id
    else
      h = args
      b_to = nil
      b_to_id = nil
    end

    thread = self.thread(b_to_id)
    if thread.size == 0
      n = self.new(entity: h.to_s, entity_type: SNAPSHOT, belongs_to_id: b_to_id)
      return n.save
    else
      s = self.snapshot(b_to_id)
      last_e = thread.find_by(next: nil)
      last_e.next = NEXT_ID_PENDING
      unless last_e.save
        return false
      end
      d = HashDiffSym.diff(eval(s.entity), h)
      n = self.new(entity: d.to_s, entity_type: DIFF, previous: last_e.id, belongs_to_id: b_to_id)

      if n.save
        last_e.next = n.id
        if last_e.save
          return true
        else
          n.destroy
          return false
        end
      else
        return false
      end
    end
  end

  def self.snapshot(b_to_id = nil)
    thread = self.thread(b_to_id)
    last_s = thread.find_by(next: nil)
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

  private
    def self.thread(b_to_id)
      if b_to_id == nil
        return self.where("belongs_to_id is NULL")
      else
        return self.where("belongs_to_id = ?", b_to_id)
      end
    end
end
