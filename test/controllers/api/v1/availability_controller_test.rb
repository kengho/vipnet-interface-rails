require "test_helper"

class Api::V1::AvailabilityControllerTest < ActionController::TestCase
  setup do
    ncc_node = CurrentNccNode.new(network: networks(:network1), vid: "0x1a0e0001")
    ncc_node.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node,
      coordinator: coordinators(:coordinator1),
      accessip: "198.51.100.1",
    )
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
