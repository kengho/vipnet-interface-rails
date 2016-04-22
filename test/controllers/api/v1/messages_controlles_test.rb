class Api::V1::MessagesControllerTest < ActionController::TestCase
  test "validations" do
    # correct token should be provided
    post(:create)
    assert_response :unauthorized

    # message should be provided
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    post(:create, { message: nil, source: "ncc", vipnet_network_id: "6670" })
    assert_equal("error", @response.body)

    # source should be provided
    post(:create, { message: "message", source: nil, vipnet_network_id: "6670" })
    assert_equal("error", @response.body)

    # vipnet_network_id should be provided
    post(:create, { message: "message", source: "ncc", vipnet_network_id: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    Message.destroy_all
    Node.destroy_all
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""

    post(:create, { message: "meaningless message", source: "ncc", vipnet_network_id: "6670" })
    message_size = Message.all.size
    assert_equal(1, message_size)
    assert_equal("ok", @response.body)

    post(:create, { message: "01.01.00 00:00:00 Create DB\\NodeName 0", source: "ncc", vipnet_network_id: "6670" })
    assert_equal(message_size + 1, Message.all.size)
    message_size += 1
    assert_equal("post nodename.doc", @response.body)


    client1 = Node.new(vipnet_id: "0x1a0e000b", name: "client1", network_id: networks(:network1).id)
    client1.save!

    post(:create, { message: "01.01.00 00:00:00 AddUN: client1 ID=1A0E1234 NO=1A0E000B", source: "ncc", vipnet_network_id: "6670" })
    assert_equal(message_size + 1, Message.all.size)
    message_size += 1
    client1 = Node.find_by_id(client1.id)
    assert client1.created_by_message_id

    post(:create, { message: "01.01.00 00:00:00 DelUN: client1 UG=1A0E1234 NO=1A0E000B", source: "ncc", vipnet_network_id: "6670" })
    assert_equal(message_size + 1, Message.all.size)
    message_size += 1
    # client1 should be marked as deleted, thus creating history
    assert_equal(2, Node.all.size)
    client1_old = Node.find_by_id(client1.id)
    assert_equal(true, client1_old.history)
    assert client1_old.deleted_by_message_id
    assert client1_old.deleted_at
    client1_actual = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert client1_actual
    assert client1_actual.deleted_by_message_id
    assert client1_actual.deleted_at
  end
end
