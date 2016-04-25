class Api::V1::IplirconfsControllerTest < ActionController::TestCase
  test "validations" do
    # correct token should be provided
    post(:create)
    assert_response :unauthorized

    # content should be provided
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""
    post(:create, { content: nil, vipnet_id: "0x1a0e000a" })
    assert_equal("error", @response.body)

    # vipnet_id should be provided
    iplirconf_empty = fixture_file_upload("iplirconfs/empty.conf", "application/octet-stream")
    post(:create, { content: iplirconf_empty, vipnet_id: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    # prepare configuration, where there are
    # 0x1a0e000a coordinator1,
    # 0x1a0e000b administrator,
    # 0x1a0e000c client1 (renamed),
    # 0x1a0e000d coordinator2
    Node.destroy_all
    Nodename.destroy_all
    Iplirconf.destroy_all
    Network.destroy_all
    Coordinator.destroy_all
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    iplirconfs_controller = @controller
    @controller = Api::V1::NodenamesController.new
    added_coordinator2_nodename = fixture_file_upload("nodenames/03_added_coordinator2.doc", "application/octet-stream")
    post(:create, { content: added_coordinator2_nodename, vipnet_network_id: "6670" })
    @controller = iplirconfs_controller
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""

    # upload iplirconf with administrator, client1 and coordinator1
    initial_iplirconf = fixture_file_upload("iplirconfs/00_0x1a0e000a_initial.conf", "application/octet-stream")
    post(:create, { content: initial_iplirconf, vipnet_id: "0x1a0e000a" })
    assert_equal("ok", @response.body)
    node_size = Node.all.size
    assert_equal(7, node_size)
    # coordinator1
    coordinator1 = Node.where("vipnet_id = '0x1a0e000a' AND history = 'false'").first
    assert_equal(["192.0.2.1", "192.0.2.3"], eval(coordinator1.ips["0x1a0e000a"]))
    assert_equal("192.0.2.1, 192.0.2.3", coordinator1.ips["summary"])
    assert_equal("3.0-670", coordinator1.vipnet_version["0x1a0e000a"])
    assert_equal("3.0-670", coordinator1.vipnet_version["summary"])
    # administrator
    administrator = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert_equal(["192.0.2.5",], eval(administrator.ips["0x1a0e000a"]))
    assert_equal("192.0.2.5", administrator.ips["summary"])
    assert_equal("3.2-672", administrator.vipnet_version["0x1a0e000a"])
    assert_equal("3.2-672", administrator.vipnet_version["summary"])
    assert_equal(["198.51.100.2"], administrator.accessips)
    # client1
    client1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert_equal(["192.0.2.7",], eval(client1.ips["0x1a0e000a"]))
    assert_equal("192.0.2.7", client1.ips["summary"])
    assert_equal("0.3-2", client1.vipnet_version["0x1a0e000a"])
    assert_equal("0.3-2", client1.vipnet_version["summary"])
    assert_equal(["198.51.100.3"], client1.accessips)

    # nothing changed
    iplirconf_before = Iplirconf.all
    nodename_before = Nodename.all
    node_before = Nodename.all
    initial_iplirconf = fixture_file_upload("iplirconfs/00_0x1a0e000a_initial.conf", "application/octet-stream")
    post(:create, { content: initial_iplirconf, vipnet_id: "0x1a0e000a" })
    iplirconf_after = Iplirconf.all
    nodename_after = Nodename.all
    node_after = Nodename.all
    assert_equal(iplirconf_after, iplirconf_before)
    assert_equal(nodename_after, nodename_before)
    assert_equal(node_after, node_before)

    # 01_added_0x1a0e000d
    added_0x1a0e000d_iplirconf = fixture_file_upload("iplirconfs/01_added_0x1a0e000d.conf", "application/octet-stream")
    post(:create, { content: added_0x1a0e000d_iplirconf, vipnet_id: "0x1a0e000a" })
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1
    # coordinator2
    coordinator2 = Node.where("vipnet_id = '0x1a0e000d' AND history = 'false'").first
    assert_equal(["192.0.2.9", "192.0.2.10"], eval(coordinator2.ips["0x1a0e000a"]))
    assert_equal("192.0.2.9, 192.0.2.10", coordinator2.ips["summary"])
    assert_equal("3.0-670", coordinator2.vipnet_version["0x1a0e000a"])
    assert_equal("3.0-670", coordinator2.vipnet_version["summary"])
    assert_equal(["198.51.100.4"], coordinator2.accessips)

    # 02_changed_client1_and_administrator
    # administrator "ip= 192.0.2.55" => "ip= 192.0.2.5"
    # administrator "version= 3.2-672" => "version= 3.2-673"
    # client1 "accessip= 198.51.100.3" => "accessip= 192.0.2.7"
    changed_iplirconf = fixture_file_upload("iplirconfs/02_0x1a0e000a_changed.conf", "application/octet-stream")
    post(:create, { content: changed_iplirconf, vipnet_id: "0x1a0e000a" })
    assert_equal(node_size + 2, Node.all.size)
    node_size += 2
    client1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert_equal(["192.0.2.7"], client1.accessips)
    administrator = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert_equal(["192.0.2.55",], eval(administrator.ips["0x1a0e000a"]))
    assert_equal("192.0.2.55", administrator.ips["summary"])
    assert_equal("3.2-673", administrator.vipnet_version["0x1a0e000a"])
    assert_equal("3.2-673", administrator.vipnet_version["summary"])

    # 03_0x1a0e000d_initial
    coordinator2_initial_iplirconf = fixture_file_upload("iplirconfs/03_0x1a0e000d_initial.conf", "application/octet-stream")
    post(:create, { content: coordinator2_initial_iplirconf, vipnet_id: "0x1a0e000d" })
    assert_equal(node_size + 4, Node.all.size)
    node_size += 4
    # coordinator1
    coordinator1 = Node.where("vipnet_id = '0x1a0e000a' AND history = 'false'").first
    assert coordinator1.ips["0x1a0e000a"]
    assert_equal(["192.0.2.1", "192.0.2.3"], eval(coordinator1.ips["0x1a0e000a"]))
    assert_equal(["192.0.2.1", "192.0.2.3"], eval(coordinator1.ips["0x1a0e000d"]))
    assert_equal("192.0.2.1, 192.0.2.3", coordinator1.ips["summary"])
    assert coordinator1.vipnet_version["0x1a0e000a"]
    assert_equal("3.0-670", coordinator1.vipnet_version["0x1a0e000a"])
    assert_equal("3.0-670", coordinator1.vipnet_version["0x1a0e000d"])
    assert_equal("3.0-670", coordinator1.vipnet_version["summary"])
    # administrator
    administrator = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert administrator.ips["0x1a0e000a"]
    assert_equal(["192.0.2.55",], eval(administrator.ips["0x1a0e000a"]))
    assert_equal(["192.0.2.55",], eval(administrator.ips["0x1a0e000d"]))
    assert_equal("192.0.2.55", administrator.ips["summary"])
    assert administrator.vipnet_version["0x1a0e000a"]
    assert_equal("3.2-673", administrator.vipnet_version["0x1a0e000a"])
    assert_equal("3.2-673", administrator.vipnet_version["0x1a0e000d"])
    assert_equal("3.2-673", administrator.vipnet_version["summary"])
    assert_equal(["198.51.100.2", "203.0.113.2"], administrator.accessips)
    # client1
    client1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert client1.ips["0x1a0e000d"]
    assert_equal(["192.0.2.7",], eval(client1.ips["0x1a0e000a"]))
    assert_equal(["192.0.2.7",], eval(client1.ips["0x1a0e000d"]))
    assert_equal("192.0.2.7", client1.ips["summary"])
    assert client1.vipnet_version["0x1a0e000d"]
    assert_equal("0.3-2", client1.vipnet_version["0x1a0e000a"])
    assert_equal("0.3-2", client1.vipnet_version["0x1a0e000d"])
    assert_equal("0.3-2", client1.vipnet_version["summary"])
    assert_equal(["192.0.2.7", "203.0.113.3"], client1.accessips)
    # coordinator2
    coordinator2 = Node.where("vipnet_id = '0x1a0e000d' AND history = 'false'").first
    assert coordinator2.ips["0x1a0e000d"]
    assert_equal(["192.0.2.9", "192.0.2.10"], eval(coordinator2.ips["0x1a0e000a"]))
    assert_equal(["192.0.2.9", "192.0.2.10"], eval(coordinator2.ips["0x1a0e000d"]))
    assert_equal("192.0.2.9, 192.0.2.10", coordinator2.ips["summary"])
    assert_equal("3.0-670", coordinator2.vipnet_version["0x1a0e000a"])
    assert_equal("3.0-670", coordinator2.vipnet_version["0x1a0e000d"])
    assert_equal("3.0-670", coordinator2.vipnet_version["summary"])
    assert_equal(["198.51.100.4"], coordinator2.accessips)

    # 04_0x1a0e000d_changed
    # coordinator1 "ip= 192.0.2.1" => "ip= 192.0.2.51"
    # administrator "version= 3.2-673" => "version= 3.2-672"
    changed_iplirconf = fixture_file_upload("iplirconfs/04_0x1a0e000d_changed.conf", "application/octet-stream")
    post(:create, { content: changed_iplirconf, vipnet_id: "0x1a0e000d" })
    assert_equal(node_size + 2, Node.all.size)
    node_size += 2
    # coordinator1
    coordinator1 = Node.where("vipnet_id = '0x1a0e000a' AND history = 'false'").first
    assert_equal(["192.0.2.51", "192.0.2.3"], eval(coordinator1.ips["0x1a0e000d"]))
    assert_equal("192.0.2.1, 192.0.2.3, 192.0.2.51", coordinator1.ips["summary"])
    # administrator
    administrator = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    assert_equal("3.2-672", administrator.vipnet_version["0x1a0e000d"])
    assert_equal("?", administrator.vipnet_version["summary"])
    
    # test Node#update_all at the same time, as long as everything is already prepared
    administrator = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    administrator_attributes_before = administrator.attributes.reject { |key, _| key == "id" }
    # start messing with administrator
    administrator.ips = {}
    administrator.vipnet_version = {}
    administrator.enabled = ""
    administrator.category = ""
    administrator.abonent_number = ""
    administrator.server_number = ""
    Node.record_timestamps = false
    administrator.save!
    administrator_after_messing = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    administrator_attributes_after_messing = administrator_after_messing.attributes.reject { |key, _| key == "id" }
    # check if messing was successful
    assert_not_equal(administrator_attributes_after_messing, administrator_attributes_before)
    Node.update_all
    administrator_after_update_all = Node.where("vipnet_id = '0x1a0e000b' AND history = 'false'").first
    administrator_attributes_after_update_all = administrator_after_update_all.attributes.reject { |key, _| key == "id" }
    # check if everything is back to normal
    assert_equal(administrator_attributes_after_update_all, administrator_attributes_before)
  end
end
