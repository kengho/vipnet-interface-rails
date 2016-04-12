class Api::V1::NodesControllerTest < ActionController::TestCase
  test "nodes" do
    get(:index, { vipnet_id: "0x1a0e0701", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "name" => "client0x1a0e0701", "enabled" => true }}, assigns["response"])

    get(:index, { vipnet_id: "0x1a0e0701", only: ["ips", "category"], token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "ips" => { "summary" => "192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4" }, "category" => "client" }}, assigns["response"])

    get(:index, { vipnet_id: "unmatched id", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])

    # multiple nodes found
    get(:index, { vipnet_id: "0x1a0e0702", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("internal", assigns["response"][:errors][0][:title])

    get(:index, { not_vipnet_id_param: "true", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })
  end
end
