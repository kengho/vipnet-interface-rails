require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    @ticket_system2 = TicketSystem.create!(url_template: "http://tickets2.org/ticket_id={id}")
    @ncc_node = CurrentNccNode.new(network: networks(:network1), vid: "0x1a0e0001")
  end

  test "should not save without ticket_system" do
    ticket = Ticket.new(vid: "0x1a0e0001", ticket_id: "1")
    assert_not ticket.save
  end

  test "should not save without vid" do
    ticket = Ticket.new(ticket_system: @ticket_system1, ticket_id: "1")
    assert_not ticket.save
  end

  test "should not save without ticket_id" do
    ticket = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0001")
    assert_not ticket.save
  end

  test "should not save same ticket_system for such vid and ticket_id" do
    ticket1 = Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket3 = Ticket.new(ticket_system: @ticket_system2, vid: "0x1a0e0001", ticket_id: "1")
    assert_not ticket2.save
    assert ticket3.save
  end

  test "should not save same vid for such ticket_system and ticket_id" do
    ticket1 = Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket3 = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0002", ticket_id: "1")
    assert_not ticket2.save
    assert ticket3.save
  end

  test "should not save same ticket_id for such ticket_system and vid" do
    ticket1 = Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    ticket3 = Ticket.new(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "2")
    assert_not ticket2.save
    assert ticket3.save
  end

  test "when ticket_system destroys, all its tickets destroys" do
    Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "2")
    Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "3")
    assert_equal(3, Ticket.all.size)
    @ticket_system1.destroy
    assert_equal(0, Ticket.all.size)
  end

  test "when ncc_node destroys, foreign_key nullifies" do
    Ticket.create!(ticket_system: @ticket_system1, ncc_node: @ncc_node, vid: "0x1a0e0001", ticket_id: "1")
    assert Ticket.first.ncc_node_id
    @ncc_node.destroy
    assert_not Ticket.first.ncc_node_id
  end
end
