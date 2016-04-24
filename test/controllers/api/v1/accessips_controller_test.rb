class Api::V1::AccessipsControllerTest < ActionController::TestCase
  test "accessips" do
    get(:index, { accessip: "192.0.2.1", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "vipnet_id" => "0x1a0e0100", "enabled" => true }}, assigns["response"])

    get(:index, { accessip: "unmatched ip", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])

    # multiple nodes found
    get(:index, { accessip: "192.0.2.3", token: "GET_INFORMATION_TOKEN" })
    p assigns["response"]
    assert assigns["response"][:errors]
    assert_equal("internal", assigns["response"][:errors][0][:title])

    get(:index, { not_accessip_param: "true", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })

    get(:index, { token: "not a valid token" })
    assert_response :unauthorized
  end
end
