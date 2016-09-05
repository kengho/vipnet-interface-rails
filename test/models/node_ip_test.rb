require "test_helper"

class NodeIpTest < ActiveSupport::TestCase
  setup do
    ncc_node = NccNode.new(network: networks(:network1), vid: "0x1a0e0001")
    @hw_node = HwNode.new(coordinator: coordinators(:coordinator1), ncc_node: ncc_node)
  end

  test "shouldn't save without hw_node" do
    node_ip = NodeIp.new(u32: 0)
    assert_not node_ip.save
  end

  test "shouldn't save second ip for same hw_node" do
    node_ip1 = NodeIp.new(u32: 0, hw_node: @hw_node)
    assert node_ip1.save
    node_ip2 = NodeIp.new(u32: 0, hw_node: @hw_node)
    assert_not node_ip2.save
  end

  test "shouldn't save wrong u32" do
    node_ip1 = NodeIp.new(u32: -1, hw_node: @hw_node)
    node_ip2 = NodeIp.new(u32: 0x100000000.to_i, hw_node: @hw_node)
    assert_not node_ip1.save
    assert_not node_ip2.save
  end

  test "when hw_node destroys, all its node_ips destroys" do
    NodeIp.create!(u32: 0, hw_node: @hw_node)
    assert_equal(1, NodeIp.all.size)
    @hw_node.destroy
    assert_equal(0, NodeIp.all.size)
  end
end
