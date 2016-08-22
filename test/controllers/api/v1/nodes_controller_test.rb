require "test_helper"

class Api::V1::NodesControllerTest < ActionController::TestCase
  setup do
    CurrentNode.create!(
      vid: "0x1a0e0001",
      name: "client-0x1a0e0001",
      network: networks(:network1),
      ip: {
        "0x1a0e000a" => "198.51.100.1",
        "0x1a0e000d" => "198.51.100.1",
      },
      accessip: {
        "0x1a0e000a" => "198.51.100.1",
        "0x1a0e000d" => "203.0.113.1",
      },
      version: {
        "0x1a0e000a" => "3.0-670",
        "0x1a0e000d" => "3.0-670",
      },
      version_decoded: {
        "0x1a0e000a" => "3.1",
        "0x1a0e000d" => "3.1",
      },
      enabled: true,
      category: "client",
      creation_date: DateTime.now,
      creation_date_accuracy: true,
    )
  end

  test "should return error if no valid token provided" do
    get(:index, { token: "incorrect token" })
    assert_response :unauthorized
  end

  test "should return error if vid not provided" do
    get(:index, { token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })
  end

  test "should return error if vid not found" do
    get(:index, { vid: "unmatched id", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
  end

  test "should return information" do
    get(:index, { vid: "0x1a0e0001", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "name" => "client-0x1a0e0001" }}, assigns["response"])
  end

  test "should return information using only" do
    get(:index, { vid: "0x1a0e0001", only: ["ip", "category", "jibberish"], token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: {
      "ip" => {
        "0x1a0e000a" => "198.51.100.1",
        "0x1a0e000d" => "198.51.100.1",
      },
      "category" => "client",
    }}, assigns["response"])
  end
end
