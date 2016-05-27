require "test_helper"

class Api::V1::NodenamesControllerTest < ActionController::TestCase
  test "validations" do
    # correct token should be provided
    post(:create)
    assert_response :unauthorized

    # content should be provided
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    post(:create, { content: nil, vipnet_network_id: "6670" })
    assert_equal("error", @response.body)

    # vipnet_network_id should be provided
    nodename_empty = fixture_file_upload("nodenames/empty.doc", "application/octet-stream")
    post(:create, { content: nodename_empty, vipnet_network_id: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    Node.destroy_all
    Nodename.destroy_all
    Network.destroy_all
    Settings.networks_to_ignore = ""

    # 00_initial
    initial_nodename = fixture_file_upload("nodenames/00_initial.doc", "application/octet-stream")
    post(:create, { content: initial_nodename, vipnet_network_id: "6670" })
    assert_equal("ok", @response.body)
    # created 2 nodes: administrator, coordintor
    node_size = Node.all.size
    assert_equal(2, node_size)
    coordintor = Node.where("vipnet_id = '0x1a0e000a'").first
    assert_equal("coordinator1", coordintor.name)
    assert_equal(false, coordintor.history)
    assert_equal(true, coordintor.enabled)
    assert_equal("server", coordintor.category)
    assert_equal(false, coordintor.created_first_at_accuracy)
    assert_equal("0000", coordintor.abonent_number)
    assert_equal("0001", coordintor.server_number)
    administrator = Node.where("vipnet_id = '0x1a0e000b'").first
    assert_equal("administrator", administrator.name)
    assert_equal(false, administrator.history)
    assert_equal(true, administrator.enabled)
    assert_equal("client", administrator.category)
    assert_equal(false, administrator.created_first_at_accuracy)
    assert_equal("0001", administrator.abonent_number)
    assert_equal("0001", administrator.server_number)
    # created 1 network
    assert_equal(1, Network.all.size)
    assert_equal("6670", Network.first.vipnet_network_id)
    # created 1 nodename
    assert_equal(1, Nodename.all.size)

    # 01_added client1
    added_client1_nodename = fixture_file_upload("nodenames/01_added_client1.doc", "application/octet-stream")
    post(:create, { content: added_client1_nodename, vipnet_network_id: "6670" })
    client1 = Node.where("vipnet_id = '0x1a0e000c'").first
    assert_equal(true, client1.created_first_at_accuracy)
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1

    # 02_renamed_client1
    renamed_client1_nodename = fixture_file_upload("nodenames/02_renamed_client1.doc", "application/octet-stream")
    post(:create, { content: renamed_client1_nodename, vipnet_network_id: "6670" })
    # added one node to history
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1
    client1_old = Node.where("vipnet_id = '0x1a0e000c' AND history = 'true'").first
    assert client1_old
    client1_renamed1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert_equal("client1-renamed1", client1_renamed1.name)

    # 03_added_coordinator2
    added_coordinator2_nodename = fixture_file_upload("nodenames/03_added_coordinator2.doc", "application/octet-stream")
    post(:create, { content: added_coordinator2_nodename, vipnet_network_id: "6670" })
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1

    # 04_client1_moved_to_coordinator2
    client1_moved_to_coordinator2_nodename = fixture_file_upload("nodenames/04_client1_moved_to_coordinator2.doc", "application/octet-stream")
    post(:create, { content: client1_moved_to_coordinator2_nodename, vipnet_network_id: "6670" })
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1
    client1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert_equal("0001", client1.abonent_number)
    assert_equal("0002", client1.server_number)

    # 05_client1_disabled
    client1_disabled_nodename = fixture_file_upload("nodenames/05_client1_disabled.doc", "application/octet-stream")
    post(:create, { content: client1_disabled_nodename, vipnet_network_id: "6670" })
    assert_equal(node_size + 1, Node.all.size)
    node_size += 1
    client1 = Node.where("vipnet_id = '0x1a0e000c' AND history = 'false'").first
    assert_equal(false, client1.enabled)

    # 06_added_node_from_ignoring_network
    Settings.networks_to_ignore = "6671"
    added_node_from_ignoring_network_nodename = fixture_file_upload("nodenames/06_added_node_from_ignoring_network.doc", "application/octet-stream")
    post(:create, { content: added_node_from_ignoring_network_nodename, vipnet_network_id: "6670" })
    assert_equal(node_size, Node.all.size)
    node_size += 0
    Settings.networks_to_ignore = ""

    # 07_added_internetworking_node_from_network_we_admin
    another_network_we_admin = Network.new(vipnet_network_id: "6672")
    another_network_we_admin.save
    another_network_we_admin_nodename = Nodename.new(network_id: another_network_we_admin.id)
    another_network_we_admin_nodename.save
    added_internetworking_node_we_admins_nodename = fixture_file_upload("nodenames/07_added_internetworking_node_we_admins.doc", "application/octet-stream")
    post(:create, { content: added_internetworking_node_we_admins_nodename, vipnet_network_id: "6670" })
    assert_equal(node_size, Node.all.size)
    node_size += 0
    another_network_we_admin.destroy
    another_network_we_admin_nodename.destroy
  end
end
