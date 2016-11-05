require "test_helper"

class HwNodesTest < ActiveSupport::TestCase
  setup do
    @ncc_node = CurrentNccNode.new(network: networks(:network1), vid: "0x1a0e0001"); @ncc_node.save!
    @coordinator = coordinators(:coordinator1)
  end

  test "shouldn't save CurrentHwNode without ncc_node" do
    current_hw_node = CurrentHwNode.new(coordinator: @coordinator)
    assert_not current_hw_node.save
  end

  test "shouldn't save DeletedHwNode without ncc_node" do
    deleted_hw_node = DeletedHwNode.new(coordinator: @coordinator)
    assert_not deleted_hw_node.save
  end

  test "shouldn't save CurrentHwNode without coordinator" do
    current_hw_node = CurrentHwNode.new(ncc_node: @ncc_node)
    assert_not current_hw_node.save
  end

  test "shouldn't save DeletedHwNode without coordinator" do
    deleted_hw_node = DeletedHwNode.new(ncc_node: @ncc_node)
    assert_not deleted_hw_node.save
  end

  test "shouldn't save two CurrentHwNode with ncc_node and coordinator" do
    current_hw_node1 = CurrentHwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    current_hw_node2 = CurrentHwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    assert current_hw_node1.save
    assert_not current_hw_node2.save
  end

  test "shouldn't save two DeletedHwNode with ncc_node and coordinator" do
    deleted_hw_node1 = DeletedHwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    deleted_hw_node2 = DeletedHwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    assert deleted_hw_node1.save
    assert_not deleted_hw_node2.save
  end

  test "shouldn't save HwNode without descendant" do
    hw_node = HwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_not hw_node.save
  end

  test "when ncc_node destroys, all its hw_nodes destroys" do
    CurrentHwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, CurrentHwNode.all.size)
    @ncc_node.destroy
    assert_equal(0, CurrentHwNode.all.size)
  end

  test "when coordinator destroys, all its hw_nodes destroys" do
    CurrentHwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, CurrentHwNode.all.size)
    @coordinator.destroy
    assert_equal(0, CurrentHwNode.all.size)
  end
end
