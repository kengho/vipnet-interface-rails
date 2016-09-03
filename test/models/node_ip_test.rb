require "test_helper"

class NodeIpTest < ActiveSupport::TestCase
  test "shouldn't save without node" do
    ip = NodeIp.new(u32: 0, coordinator: coordinators(:coordinator1))
    assert_not ip.save
  end

  test "shouldn't save without coordinator" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: networks(:network1))
    node.save!
    ip = NodeIp.new(u32: 0, node: node)
    assert_not ip.save
  end

  test "shouldn't save second ip for same node and same coordinator" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: networks(:network1))
    node.save!
    ip1 = NodeIp.new(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert ip1.save
    ip2 = NodeIp.new(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert_not ip2.save
  end

  test "when coordinator destroys, all its node_ips destroys" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: networks(:network1))
    node.save!
    NodeIp.create!(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert_equal(1, NodeIp.all.size)
    coordinators(:coordinator1).destroy
    assert_equal(0, NodeIp.all.size)
  end

  test "when node destroys, all its node_ips destroys" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: networks(:network1))
    node.save!
    NodeIp.create!(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert_equal(1, NodeIp.all.size)
    node.destroy
    assert_equal(0, NodeIp.all.size)
  end
end
