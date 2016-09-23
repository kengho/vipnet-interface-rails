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

  def assert_ncc_nodes_should_be(expected_ncc_nodes)
    assert_equal(
      expected_ncc_nodes.sort_by_vid,
      eval(NccNode.to_json_ncc).sort_by_vid
    )
  end

  def assert_ncc_nodes_ascendants_should_be(expected_ncc_nodes_ascendants)
    assert_equal(
      expected_ncc_nodes_ascendants.sort_by_descendant,
      eval(NccNode.to_json_ascendants).sort_by_descendant
    )
  end

  def assert_hw_nodes_should_be(expected_hw_nodes)
    assert_equal(
      expected_hw_nodes.sort_by_ncc_node_and_coordinator,
      eval(CurrentHwNode.to_json_hw).sort_by_ncc_node_and_coordinator
    )
  end

  def assert_node_ips_should_be(expected_node_ips)
    assert_equal(
      expected_node_ips.sort_by_hw_node_and_u32,
      eval(NodeIp.to_json_nonmagic).sort_by_hw_node_and_u32
    )
  end
end

class Array
  def sort_by_vid
    self.sort_by { |h| h[:vid] }
  end

  def sort_by_ncc_node_and_coordinator
    self.sort_by { |h| [h[:ncc_node_id], h[:coordinator_id]] }
  end

  def sort_by_hw_node_and_u32
    self.sort_by { |h| [h[:hw_node_id], h[:u32]] }
  end

  def sort_by_descendant
    self.sort_by { |h| [h[:descendant_type], h[:descendant_vid]] }
  end

  def which_indexes(hash)
    indexes = []
    self.each_with_index do |_, i|
      indexes.push(i) if self[i] == self[i].merge(hash)
    end
    indexes
  end

  def find_by(where)
    indexes = which_indexes(where)
    self[indexes.first]
  end

  def change_where(where, changes)
    indexes = which_indexes(where)
    indexes.each do |index|
      self[index].deep_merge!(changes)
    end
  end

  def delete_where(where)
    indexes = which_indexes(where)
    indexes.each do |index|
      self[index] = :to_delete
    end
    self.delete_if { |e| e == :to_delete }
  end
end

class CurrentNccNode::ActiveRecord_Relation
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
