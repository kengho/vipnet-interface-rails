ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
# http://stackoverflow.com/a/10980700/6376451
include ActionDispatch::TestProcess

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  ENV["GET_INFORMATION_TOKEN"] = "GET_INFORMATION_TOKEN"
  ENV["POST_ADMINISTRATOR_TOKEN"] = "POST_ADMINISTRATOR_TOKEN"
  ENV["CHECKER_TOKEN"] = "CHECKER_TOKEN"
  ENV["DEFAULT_LOCALE"] = "DEFAULT_LOCALE"
  ENV["POST_HW_TOKEN"] = "POST_HW_TOKEN"
  ENV["POST_TICKETS_TOKEN"] = "POST_TICKETS_TOKEN"

  def ncc_nodes_should_be(expected_ncc_nodes)
    assert_equal(expected_ncc_nodes.sort_by_vid, eval(CurrentNccNode.to_json_ncc).sort_by_vid)
  end
end

class Array
  def sort_by_vid
    self.sort_by { |h| h[:vid] }
  end

  def which_index(hash)
    self.each_with_index do |_, i|
      return i if self[i] == self[i].merge(hash)
    end
  end

  def change_where(where, changes)
    index = which_index(where)
    if changes == nil
      self.delete_at(index)
    elsif changes.class == Hash
      self[index].deep_merge!(changes)
    end
  end
end

class NccNode::ActiveRecord_Relation
  def vids
    vids = []
    self.each { |n| vids.push(n.vid) }
    vids.sort
  end
end

class ActionController::TestCase
  require "authlogic/test_case"
  setup :activate_authlogic
end
