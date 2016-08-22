require "test_helper"

class Api::V1::AvailabilityControllerTest < ActionController::TestCase
  setup do
    Coordinator.new(vid: "0x1a0e000a").save(validate: false)
    Coordinator.new(vid: "0x1a0e000d").save(validate: false)

    CurrentNode.new(
      vid: "0x1a0e0001",
      accessip: {
        "0x1a0e000a" => "198.51.100.1",
        "0x1a0e000d" => "203.0.113.1",
      },
    ).save(validate: false)
  end

  test "should return error when no valid token provided" do
    get(:index, { token: "incorrect token" })
    assert_response :unauthorized
  end

  test "should return error if vid not provided" do
    get(:index, { token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })
  end

  test "should return availability" do
    get(:index, { vid: "0x1a0e0001", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "availability" => true }}, assigns["response"])
  end

  test "should return error if vid not found" do
    get(:index, { vid: "nonexistent vid", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
  end
end
