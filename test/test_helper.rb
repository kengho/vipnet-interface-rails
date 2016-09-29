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
    msg = HashDiffSym.diff(
      expected_ncc_nodes.sort_ncc,
      eval(NccNode.to_json_ncc).sort_ncc
    )
    assert_equal(
      expected_ncc_nodes.sort_ncc,
      eval(NccNode.to_json_ncc).sort_ncc,
      msg
    )
  end

  def assert_hw_nodes_should_be(expected_hw_nodes)
    msg = HashDiffSym.diff(
      expected_hw_nodes.sort_hw,
      eval(HwNode.to_json_hw).sort_hw
    )
    assert_equal(
      expected_hw_nodes.sort_hw,
      eval(HwNode.to_json_hw).sort_hw,
      msg
    )
  end

  def last_nodename_created_at(network)
    Nodename.thread(network).last.created_at.iso8601(3)
  end

  def last_iplirconf_created_at(coordinator)
    Iplirconf.thread(coordinator).last.created_at.iso8601(3)
  end

end

class Array

  def sort_ncc
    self.sort! do |a, b|
      if a[:vid] && b[:vid]
        a[:vid] <=> b[:vid]
      elsif a[:vid] && b[:descendant_vid]
        1
      elsif a[:descendant_vid] && b[:vid]
        -1
      elsif a[:descendant_vid] && b[:descendant_vid]
        a[:creation_date] <=> b[:creation_date]
      end
    end
  end

  def sort_hw
    self.sort! do |a, b|
      if a[:ncc_node_vid] && a[:coord_vid] &&
         b[:ncc_node_vid] && b[:coord_vid]
        [a[:ncc_node_vid], a[:coord_vid], a[:creation_date]] <=>
        [b[:ncc_node_vid], b[:coord_vid], b[:creation_date]]
      elsif a[:ncc_node_vid] && a[:coord_vid] && b[:descendant_vid] && b[:descendant_coord_vid]
        1
      elsif a[:descendant_vid] && a[:descendant_coord_vid] && b[:ncc_node_vid] && b[:coord_vid]
        -1
      elsif a[:descendant_vid] && a[:descendant_coord_vid] &&
            b[:descendant_vid] && b[:descendant_coord_vid]
        [a[:descendant_vid], a[:descendant_coord_vid], a[:creation_date]] <=>
        [b[:descendant_vid], b[:descendant_coord_vid], b[:creation_date]]
      end
    end
  end

  def which_indexes(hash)
    indexes = []
    self.each_with_index do |_, i|
      indexes.push(i) if self[i] == self[i].merge(hash)
    end
    indexes
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
