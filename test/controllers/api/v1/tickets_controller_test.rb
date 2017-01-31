require "test_helper"

class Api::V1::TicketsControllerTest < ActionController::TestCase
  test "correct token should be provided" do
    post(:create)
    assert_response :unauthorized
  end

  test "ticket should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    post(:create)
    assert_equal("error", @response.body)
  end

  test "create" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    TicketSystem.destroy_all
    ncc_node_0x1a0e0001 = CurrentNccNode.create!(
      vid: "0x1a0e0001",
      network: networks(:network1),
    )

    post(
      :create,
      params: {
        ticket: {
          vid: "0x1a0e0001",
          id: "1",
          url_template: "http://tickets.org/ticket_id={id}",
        },
      },
    )
    ticket_system1 = TicketSystem.find_by(url_template: "http://tickets.org/ticket_id={id}")
    assert ticket_system1
    assert Ticket.find_by(
      ncc_node: ncc_node_0x1a0e0001,
      ticket_system: ticket_system1,
      vid: "0x1a0e0001",
      ticket_id: "1",
    )

    post(
      :create,
      params: {
        ticket: {
          vid: "0x1a0e0001",
          id: "2",
          url_template: "http://tickets.org/ticket_id={id}",
        },
      },
    )
    assert Ticket.find_by(
      ncc_node: ncc_node_0x1a0e0001,
      ticket_system: ticket_system1,
      vid: "0x1a0e0001",
      ticket_id: "2",
    )

    post(
      :create,
      params: {
        ticket: {
          vid: "0x1a0e0001",
          id: "3",
          url_template: "http://tickets2.org/ticket_id={id}",
        },
      },
    )
    ticket_system2 = TicketSystem.find_by(url_template: "http://tickets2.org/ticket_id={id}")
    assert ticket_system2
    assert Ticket.find_by(
      ncc_node: ncc_node_0x1a0e0001,
      ticket_system: ticket_system2,
      vid: "0x1a0e0001",
      ticket_id: "3",
    )

    # Ticket without "ncc_node".
    post(
      :create,
      params: {
        ticket: {
          vid: "0x1a0e0002",
          id: "1",
          url_template: "http://tickets.org/ticket_id={id}",
        },
      },
    )
    assert Ticket.find_by(
      ticket_system: ticket_system1,
      vid: "0x1a0e0002",
      ticket_id: "1",
    )
  end
end
