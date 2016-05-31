require "test_helper"

class Api::V1::NodesControllerTest < ActionController::TestCase
  test "nodes" do
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client-0x1a0e0001",
      network_id: networks(:network1).id,
      category: "client",
      history: false,
      enabled: true,
      ips: {
        "summary" => "192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4",
      }
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client-0x1a0e0001--old",
      network_id: networks(:network1).id,
      category: "client",
      history: true,
      enabled: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client-0x1a0e0002",
      network_id: networks(:network1).id,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client-0x1a0e0002",
      network_id: networks(:network1).id,
      history: false,
    ).save(validations: false)
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000a",
        },
        "client" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.1",
        },
      },
    ).save!

    get(:index, { vipnet_id: "0x1a0e0001", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "name" => "client-0x1a0e0001", "enabled" => true }}, assigns["response"])

    get(:index, { vipnet_id: "0x1a0e0001", only: ["ips", "category"], token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "ips" => { "summary" => "192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4" }, "category" => "client" }}, assigns["response"])

    get(:index, { vipnet_id: "0x1a0e0001", availability: "true", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "name" => "client-0x1a0e0001", "enabled" => true, "available" => true }}, assigns["response"])

    get(:index, { vipnet_id: "unmatched id", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])

    # multiple nodes found
    get(:index, { vipnet_id: "0x1a0e0002", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("internal", assigns["response"][:errors][0][:title])

    get(:index, { not_vipnet_id_param: "true", token: "GET_INFORMATION_TOKEN" })
    assert assigns["response"][:errors]
    assert_equal("external", assigns["response"][:errors][0][:title])
    assert_routing(assigns["response"][:errors][0][:links][:related][:href], { controller: "api/v1/doc", action: "index" })

    get(:index, { token: "not a valid token" })
    assert_response :unauthorized
  end
end
