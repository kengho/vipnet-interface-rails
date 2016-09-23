require "test_helper"

class NccNodesTest < ActiveSupport::TestCase
  setup do
    @network = networks(:network1)
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
    current_ncc_node = CurrentNccNode.new(network: @network)
    assert_not current_ncc_node.save
  end

  test "shouldn't save DeletedNccNode without vid" do
    deleted_ncc_node = DeletedNccNode.new(network: @network)
    assert_not deleted_ncc_node.save
  end

  test "shouldn't save with wrong vid" do
    ncc_node = NccNode.new(network: @network, vid: "1A0E000A")
    assert_not ncc_node.save
  end

  test "shouldn't save two CurrentNccNode with same vid" do
    current_ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network)
    current_ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network)
    assert current_ncc_node1.save
    assert_not current_ncc_node2.save
  end

  test "shouldn't save two DeletedNccNode with same vid" do
    deleted_ncc_node1 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network)
    deleted_ncc_node2 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network)
    assert deleted_ncc_node1.save
    assert_not deleted_ncc_node2.save
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

  test "when new ncc_node appears, corresponding tickets should try to connect to it" do
    ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "2")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0002", ticket_id: "3")
    ncc_node = NccNode.new(vid: "0x1a0e0001", network: @network); ncc_node.save!
    ticket1 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "2")
    ticket3 = Ticket.find_by(vid: "0x1a0e0002", ticket_id: "3")
    assert_equal(ncc_node.id, ticket1.ncc_node_id)
    assert_equal(ncc_node.id, ticket2.ncc_node_id)
    assert_not ticket3.ncc_node_id
  end
end
