class Api::V1::AccessipsControllerTest < ActionController::TestCase
  test "accessips" do
    Node.destroy_all
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client1",
      network_id: networks(:network1).id,
      enabled: true,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client2",
      network_id: networks(:network1).id,
      enabled: true,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0003",
      name: "client3",
      network_id: networks(:network1).id,
      enabled: true,
      history: false,
    ).save!
    Iplirconf.destroy_all
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000a",
        },
        "client1" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.1",
        },
        "client2" => {
          "vipnet_id" => "0x1a0e0003",
          "accessip" => "192.0.2.3",
        },
      },
    ).save!
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator2).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000b",
        },
        "client1" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.2",
        },
        "client2" => {
          "vipnet_id" => "0x1a0e0002",
          "accessip" => "192.0.2.3",
        },
      },
    ).save!

    get(:index, { accessip: "192.0.2.1", token: "GET_INFORMATION_TOKEN" })
    assert_equal({ data: { "vipnet_id" => "0x1a0e0001", "enabled" => true }}, assigns["response"])

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
