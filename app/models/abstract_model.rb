class AbstractModel < ActiveRecord::Base
  self.abstract_class = true

  def to_json_nonmagic
    self.to_json(:except => [:id, :created_at, :updated_at]).gsub("null", "nil")
  end

  def self.to_json_nonmagic
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_nonmagic))
    end
    result.to_json.gsub("null", "nil")
  end

  def to_json_for(*table_types)
    props = []
    table_types.each do |table_type|
      props += [:creation_date_accuracy] if table_type == "Nodename"
      props += table_type.constantize.props_from_api
    end
    self.to_json(:only => props + [:vid]).gsub("null", "nil")
  end

  def self.to_json_for(*table_types)
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_for(*table_types)))
    end
    result.to_json.gsub("null", "nil")
  end
end
