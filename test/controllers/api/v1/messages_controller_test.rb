require "test_helper"

class Api::V1::MessagesControllerTest < ActionController::TestCase
  test "validations" do
    # correct token should be provided
    post(:create)
    assert_response :unauthorized

    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""

    # event_name should be provided
    post(:create, { event_name: nil, datetime: "datetime" })
    assert_equal(Api::V1::BaseController::ERROR_RESPONSE, @response.body)

    # datetime should be provided
    post(:create, { event_name: "name", datetime: nil })
    assert_equal(Api::V1::BaseController::ERROR_RESPONSE, @response.body)

    # datetime should be ok
    post(:create, { event_name: "name", datetime: "not a unix datetime" })
    assert_equal(Api::V1::BaseController::ERROR_RESPONSE, @response.body)
  end

  test "create" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""

    client1 = Node.new(vipnet_id: "0x1a0e000b", name: "client1", network_id: networks(:network1).id)
    client1.save!

    datetime = "1044094272"
    post(:create, { event_name: "DelUN", datetime: datetime, vipnet_id: "1A0E000B" })
    # client should mark as deleted
    assert_equal(Api::V1::BaseController::OK_RESPONSE, @response.body)
    assert_equal(2, Node.all.size)
    old_client1 = Node.where("vipnet_id = '0x1a0e000b' AND history = 'true'").first
    assert_not old_client1.deleted_at
    new_client1 = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert_equal(Time.at(datetime.to_i).to_datetime, new_client1.deleted_at)
  end
end
