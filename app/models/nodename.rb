class Nodename < ActiveRecord::Base
  belongs_to :network
  validates :network_id,  presence: true,
                          uniqueness: true

  def changed_records(new_nodename)
    # make hashes out of nested hstore
    new_nodename_records = Hash.new
    new_nodename.records.each do |id, record|
      new_nodename_records[id] = eval(record)
    end
    self_records = Hash.new
    self.records.each do |id, record|
      self_records[id] = eval(record)
    end

    changed_records = Hash.new
    diffs = HashDiff.diff(self_records, new_nodename_records)
    diffs.each do |diff|
      change = diff[0]
      if change == "+"
        id = VipnetParser::id(diff[1])[0]
        changed_records[id] = diff[2]
      elsif change == "~"
        diff[1] =~ /(.*)\.(.*)/
        id = VipnetParser::id(Regexp.last_match(1))[0]
        prop_name = Regexp.last_match(2)
        new_value = diff[3]
        changed_records[id] = Hash.new unless changed_records[id]
        changed_records[id][prop_name.to_sym] = new_value
      elsif change == "-"
        # do nothing
      end
    end
    changed_records
  end

  def self.props_from_record
    [:name, :enabled, :category, :abonent_number, :server_number]
  end
end
