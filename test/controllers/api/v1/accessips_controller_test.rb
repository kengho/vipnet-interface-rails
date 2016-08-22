require "test_helper"

class Api::V1::AccessipsControllerTest < ActionController::TestCase
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
    CurrentNode.new(
      vid: "0x1a0e0002",
      accessip: {
        "0x1a0e000a" => "198.51.100.2",
        "0x1a0e000d" => "203.0.113.3",
      },
    ).save(validate: false)
    CurrentNode.new(
      vid: "0x1a0e0003",
      accessip: {
        "0x1a0e000a" => "198.51.100.3",
        "0x1a0e000d" => "203.0.113.3",
      },
    ).save(validate: false)
  end

  test "should return error if accessip not provided" do
    get(:index, { accessip: nil, token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })
  end

  test "should return error when no valid token provided" do
    get(:index, { token: "incorrect token" })
    assert_response :unauthorized
  end

  test "should return vid by accessip" do
    get(:index, { accessip: "198.51.100.1", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "vid" => "0x1a0e0001" }}, assigns["response"])
  end

  test "should return error if accessip not found" do
    get(:index, { accessip: "0.0.0.0", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
  end

  test "should return error if multiple nodes found" do
    get(:index, { accessip: "203.0.113.3", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("internal", assigns["response"][:errors][0][:title])
  end
end
