require "test_helper"

class NodesTest < ActiveSupport::TestCase

  test "validations" do
    network = networks(:network1)
    node1 = Node.new(vipnet_id: nil, network_id: network.id, name: "name")
    node2 = Node.new(vipnet_id: "0x1a0e0100", network_id: nil, name: "name")
    node3 = Node.new(vipnet_id: "0x1a0e0100", network_id: network.id, name: nil)
    node4 = Node.new(vipnet_id: "1A0E0100", network_id: network.id, name: "name")
    assert_not node1.save
    assert_not node2.save
    assert_not node3.save
    assert_not node4.save
  end

  test "normalize_vipnet_id" do
    vipnet_id1 = Node.normalize_vipnet_id("1A0E0100")
    vipnet_id2 = Node.normalize_vipnet_id("not looks like id at all")
    assert_equal("0x1a0e0100", vipnet_id1)
    assert_equal(false, vipnet_id2)
  end

  test "network" do
    network1 = Node.network("0x1a0e0100")
    network2 = Node.network("not looks like id at all")
    assert_equal("6670", network1)
    assert_equal(false, network2)
  end

  test "accessips" do
    node1 = Node.new(vipnet_id: "0x1a0e0100")
    node2 = nodes(:empty_node)
    assert_equal(["192.0.2.1", "192.0.2.2"], node1.accessips)
    assert_equal([], node2.accessips)
  end

  test "availability" do
    node1 = nodes(:availability1)
    node2 = nodes(:empty_node)
    assert_equal({ :data => { :availability => true }}, node1.availability)
    assert_equal({ :errors => [{ :title => "internal", :detail => "no-accessips" }]}, node2.availability)
  end

  test "ips_summary" do
    node1 = nodes(:node_ips_summary1)
    node2 = nodes(:node_ips_summary2)
    assert_equal("192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4", node1.ips_summary)
    assert_equal("", node2.ips_summary)
  end

  test "vipnet_versions_summary" do
    node1 = nodes(:vipnet_versions_summary1)
    node2 = nodes(:vipnet_versions_summary2)
    node3 = nodes(:vipnet_versions_summary3)
    assert_equal("1.1", node1.vipnet_versions_summary)
    assert_equal("?", node2.vipnet_versions_summary)
    assert_equal("", node3.vipnet_versions_summary)
  end

end
