require "test_helper"

class Api::V1::TicketsControllerTest < ActionController::TestCase
  test "validations" do
    # correct token should be provided
    post(:create)
    assert_response :unauthorized

    # ticket should be provided
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    post(:create, { ticket: nil })
    assert_equal("error", @response.body)
  end

  test "post ticket" do
    # prepare
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_TICKETS_TOKEN\""
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "test",
      network_id: networks(:network1).id,
    )
    node1.save!
    # first ticket incoming
    post(:create, {
      ticket: { vipnet_id: "0x1a0e0001", id: "1", url_template: "http://tickets.org/ticket_id=\#{id}" },
    })
    # creates new node, one goes to history
    assert_equal(Node.all.size, 2)
    node1 = Node.where("vipnet_id = ? AND history = 'false'", "0x1a0e0001").first
    assert_equal({ "http://tickets.org/ticket_id=\#{id}" => "\[\"1\"\]", "ids_summary" => "1" }, node1.tickets)
    # another ticket incoming
    post(:create, {
      ticket: { vipnet_id: "0x1a0e0001", id: "2", url_template: "http://tickets.org/ticket_id=\#{id}" },
    })
    assert_equal(Node.all.size, 3)
    node1 = Node.where("vipnet_id = ? AND history = 'false'", "0x1a0e0001").first
    assert_equal({ "http://tickets.org/ticket_id=\#{id}" => "\[\"1\", \"2\"\]", "ids_summary" => "1, 2" }, node1.tickets)
  end
end
