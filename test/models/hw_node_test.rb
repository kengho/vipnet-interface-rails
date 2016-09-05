require "test_helper"

class HwNodesTest < ActiveSupport::TestCase
  setup do
    @ncc_node = NccNode.new(network: networks(:network1), vid: "0x1a0e0001")
    @coordinator = coordinators(:coordinator1)
  end

  test "shouldn't save without ncc_node" do
    hw_node = HwNode.new(coordinator: @coordinator)
    assert_not hw_node.save
  end

  test "shouldn't save without coordinator" do
    hw_node = HwNode.new(ncc_node: @ncc_node)
    assert_not hw_node.save
  end

  test "when ncc_node destroys, all its hw_nodes destroys" do
    HwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, HwNode.all.size)
    @ncc_node.destroy
    assert_equal(0, HwNode.all.size)
  end

  test "when coordinator destroys, all its hw_nodes destroys" do
    HwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, HwNode.all.size)
    @coordinator.destroy
    assert_equal(0, HwNode.all.size)
  end
end
