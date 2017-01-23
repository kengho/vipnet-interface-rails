require "test_helper"

class AdoptTicketsTest < ActionDispatch::IntegrationTest
  test "when new ncc_node appears, corresponding tickets should try to connect to it" do
    ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "2")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0002", ticket_id: "3")
    ncc_node = CurrentNccNode.new(vid: "0x1a0e0001", network: networks(:network1))
    ncc_node.save!
    ticket1 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "2")
    ticket3 = Ticket.find_by(vid: "0x1a0e0002", ticket_id: "3")
    assert_equal(ncc_node.id, ticket1.ncc_node_id)
    assert_equal(ncc_node.id, ticket2.ncc_node_id)
    assert_not ticket3.ncc_node_id
  end
end
