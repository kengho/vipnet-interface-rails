require "test_helper"

class NccNodesTest < ActiveSupport::TestCase
  setup do
    @network1 = networks(:network1)
    @network2 = networks(:network2)
  end

  test "shouldn't save CurrentNccNode without network" do
    current_ncc_node = CurrentNccNode.new(vid: "0x1a0e0001")
    assert_not current_ncc_node.save
  end

  test "shouldn't save DeletedNccNode without network" do
    deleted_ncc_node = DeletedNccNode.new(vid: "0x1a0e0001")
    assert_not deleted_ncc_node.save
  end

  test "shouldn't save CurrentNccNode without vid" do
    current_ncc_node = CurrentNccNode.new(network: @network1)
    assert_not current_ncc_node.save
  end

  test "shouldn't save DeletedNccNode without vid" do
    deleted_ncc_node = DeletedNccNode.new(network: @network1)
    assert_not deleted_ncc_node.save
  end

  test "shouldn't save NccNode without descendant" do
    ncc_node = NccNode.new(network: @network1, vid: "0x1a0e0001")
    assert_not ncc_node.save
  end

  test "shouldn't save with wrong vid" do
    ncc_node = NccNode.new(network: @network1, vid: "1A0E000A")
    assert_not ncc_node.save
  end

  test "shouldn't save two CurrentNccNode with same vid" do
    current_ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network1)
    current_ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network1)
    assert current_ncc_node1.save
    assert_not current_ncc_node2.save
  end

  test "shouldn't save two DeletedNccNode with same vid" do
    deleted_ncc_node1 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network1)
    deleted_ncc_node2 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network1)
    assert deleted_ncc_node1.save
    assert_not deleted_ncc_node2.save
  end

  test "when network destroys, all its ncc_nodes destroys" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network1)
    assert_equal(1, NccNode.all.size)
    @network1.destroy
    assert_equal(0, NccNode.all.size)
  end
end
