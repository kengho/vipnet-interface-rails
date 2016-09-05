require "test_helper"

class Api::V1::AccessipsControllerTest < ActionController::TestCase
  setup do
    ncc_node = NccNode.new(network: networks(:network1), vid: "0x1a0e0001")
    ncc_node.save!
    HwNode.create!(
      ncc_node: ncc_node,
      coordinator: coordinators(:coordinator1),
      accessip: "198.51.100.1",
    )
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

  test "should return error when accessip is not valid IPv4" do
    get(:index, { accessip: "256.256.256.256", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_not_equal("Node not found", assigns["response"][:errors][0][:detail])
    assert_equal("external", assigns["response"][:errors][0][:title])
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
end
