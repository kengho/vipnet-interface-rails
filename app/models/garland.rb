class Garland < ActiveRecord::Base
  validates :entity, presence: true
  validates_inclusion_of :entity_type, in: [true, false]

  SNAPSHOT = false
  DIFF = true

  def self.push(args)
    # args processing
    if args.class != Hash
      return false
    end
    if args[:hash]
      h = args[:hash]
      b_to = args[:belongs_to]
    else
      h = args
    end

    # main operations
    if self.all.size == 0
      n = self.new(entity: h.to_s, entity_type: SNAPSHOT)
    else
      s = self.snapshot
      last_e = self.find_by(next: nil)
      d = HashDiffSym.diff(eval(s.entity), h)
      n = self.new(entity: d.to_s, entity_type: DIFF, previous: last_e.id)
    end

    # ending
    if b_to
      attr_name = b_to.class.name.downcase
      n.public_send("#{attr_name}=", b_to)
    end
    if last_e
      if n.save
        last_e.next = n.id
        return last_e.save
      else
        return false
      end
    else
      return n.save
    end
  end

  def self.snapshot
    last_s = self.find_by(next: nil)
    until last_s.entity_type == SNAPSHOT do
      last_s = self.find_by_id(last_s.previous)
    end
    s = last_s
    s_h = eval(s.entity)
    until s.next == nil do
      n = self.find_by_id(s.next)
      s_h = HashDiffSym.patch!(s_h, eval(n.entity))
      s = n
    end
    self.new(entity: s_h.to_s, entity_type: SNAPSHOT)
  end
end
