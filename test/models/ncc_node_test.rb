require "test_helper"

class NccNodesTest < ActiveSupport::TestCase
  setup do
    @network = networks(:network1)
  end

  test "shouldn't save without network" do
    ncc_node = NccNode.new(vid: "0x1a0e0001")
    assert_not ncc_node.save
  end

  test "shouldn't save without vid" do
    ncc_node = NccNode.new(network: @network)
    assert_not ncc_node.save
  end

  test "shouldn't save with wrong vid" do
    ncc_node = NccNode.new(network: @network, vid: "1A0E000A")
    assert_not ncc_node.save
  end

  test "when network destroys, all its ncc_nodes destroys" do
    NccNode.create!(vid: "0x1a0e0001", network: @network)
    assert_equal(1, NccNode.all.size)
    @network.destroy
    assert_equal(0, NccNode.all.size)
  end

  test "there are should be creation_date and deletion_date fields in nodes for where_date_like" do
    assert NccNode.column_names.include?("creation_date")
    assert NccNode.column_names.include?("deletion_date")
  end
end
