require "test_helper"

class Api::V1::TicketsControllerTest < ActionController::TestCase
  test "correct token should be provided" do
    post(:create)
    assert_response :unauthorized
  end

  test "ticket should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    post(:create, { ticket: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    TicketSystem.destroy_all
    CurrentNode.new(
      vid: "0x1a0e0001",
      network: networks(:network1),
    ).save!

    post(:create, {
      ticket: { vid: "0x1a0e0001", id: "1", url_template: "http://tickets.org/ticket_id={id}" },
    })
    assert_equal({ "http://tickets.org/ticket_id={id}" => "\[\"1\"\]" }, CurrentNode.find_by(vid: "0x1a0e0001").ticket)
    ticket_system1 = TicketSystem.find_by(url_template: "http://tickets.org/ticket_id={id}")
    assert ticket_system1
    assert Ticket.find_by(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "1")

    post(:create, {
      ticket: { vid: "0x1a0e0001", id: "2", url_template: "http://tickets.org/ticket_id={id}" },
    })
    assert_equal({ "http://tickets.org/ticket_id={id}" => "\[\"1\", \"2\"\]" }, CurrentNode.find_by(vid: "0x1a0e0001").ticket)
    assert Ticket.find_by(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "2")

    post(:create, {
      ticket: { vid: "0x1a0e0001", id: "3", url_template: "http://tickets2.org/ticket_id={id}" },
    })
    assert_equal({
      "http://tickets.org/ticket_id={id}"=>"[\"1\", \"2\"]",
      "http://tickets2.org/ticket_id={id}"=>"[\"3\"]"
    }, CurrentNode.find_by(vid: "0x1a0e0001").ticket)
    ticket_system2 = TicketSystem.find_by(url_template: "http://tickets2.org/ticket_id={id}")
    assert ticket_system2
    assert Ticket.find_by(ticket_system: ticket_system2, vid: "0x1a0e0001", ticket_id: "3")
  end
end
