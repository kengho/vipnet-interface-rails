require "test_helper"

class Api::V1::NodenamesControllerTest < ActionController::TestCase
  setup do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
  end

  test "correct token should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "incorrect token"
    post(:create)
    assert_response :unauthorized
  end

  test "file should be provided" do
    post(:create, { file: nil, network_vid: "6670" })
    assert_equal("error", @response.body)
  end

  test "network_vid should be provided" do
    nodename_empty = fixture_file_upload("nodenames/empty.doc", "application/octet-stream")
    post(:create, { file: nodename_empty, network_vid: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    Nodename.destroy_all
    Network.destroy_all
    Settings.networks_to_ignore = "6671"

    # 00_initial
    initial_nodename = fixture_file_upload("nodenames/00_initial.doc", "application/octet-stream")
    post(:create, { file: initial_nodename, network_vid: "6670" })
    expected_nodes = [
      {
        :vid => "0x1a0e000a",
        :name => "coordinator1",
        :enabled => true,
        :category => "server",
        :abonent_number => "0000",
        :server_number => "0001",
        :creation_date_accuracy => false,
      },
      {
        :vid => "0x1a0e000b",
        :name => "administrator",
        :enabled => true,
        :category => "client",
        :abonent_number => "0001",
        :server_number => "0001",
        :creation_date_accuracy => false,
      },
    ]
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 01_added_client1
    added_client1_nodename = fixture_file_upload("nodenames/01_added_client1.doc", "application/octet-stream")
    post(:create, { file: added_client1_nodename, network_vid: "6670" })
    expected_nodes.push(
      {
        :vid => "0x1a0e000c",
        :name => "client1",
        :enabled => true,
        :category => "client",
        :abonent_number => "0002",
        :server_number => "0001",
        :creation_date_accuracy => true,
      },
    )
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 02_renamed_client1
    renamed_client1_nodename = fixture_file_upload("nodenames/02_renamed_client1.doc", "application/octet-stream")
    post(:create, { file: renamed_client1_nodename, network_vid: "6670" })
    client1_index = expected_nodes.which_index(vid: "0x1a0e000c")
    expected_nodes[client1_index][:name] = "client1-renamed1"
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 03_added_coordinator2
    added_coordinator2_nodename = fixture_file_upload("nodenames/03_added_coordinator2.doc", "application/octet-stream")
    post(:create, { file: added_coordinator2_nodename, network_vid: "6670" })
    expected_nodes.push(
      {
        :vid => "0x1a0e000d",
        :name => "coordinator2",
        :enabled => true,
        :category => "server",
        :abonent_number => "0000",
        :server_number => "0002",
        :creation_date_accuracy => true,
      },
    )
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 04_client1_moved_to_coordinator2
    client1_moved_to_coordinator2_nodename = fixture_file_upload("nodenames/04_client1_moved_to_coordinator2.doc", "application/octet-stream")
    post(:create, { file: client1_moved_to_coordinator2_nodename, network_vid: "6670" })
    client1_index = expected_nodes.which_index(vid: "0x1a0e000c")
    expected_nodes[client1_index][:abonent_number] = "0001"
    expected_nodes[client1_index][:server_number] = "0002"
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 05_client1_disabled
    client1_disabled_nodename = fixture_file_upload("nodenames/05_client1_disabled.doc", "application/octet-stream")
    post(:create, { file: client1_disabled_nodename, network_vid: "6670" })
    client1_index = expected_nodes.which_index(vid: "0x1a0e000c")
    expected_nodes[client1_index][:enabled] = false
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 06_added_node_from_ignoring_network
    added_node_from_ignoring_network_nodename = fixture_file_upload("nodenames/06_added_node_from_ignoring_network.doc", "application/octet-stream")
    post(:create, { file: added_node_from_ignoring_network_nodename, network_vid: "6670" })
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 07_added_internetworking_node_from_network_we_admin
    # network we admin is network for such we have nodename
    another_network_we_admin = Network.new(network_vid: "6672")
    another_network_we_admin.save
    Nodename.push(hash: {}, belongs_to: another_network_we_admin)
    added_internetworking_node_we_admins_nodename = fixture_file_upload("nodenames/07_added_internetworking_node_we_admins.doc", "application/octet-stream")
    post(:create, { file: added_internetworking_node_we_admins_nodename, network_vid: "6670" })
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)
    another_network_we_admin.destroy
    Nodename.thread(another_network_we_admin).destroy_all

    # 08_group_changed
    group_changed_nodename = fixture_file_upload("nodenames/08_group_changed.doc", "application/octet-stream")
    post(:create, { file: group_changed_nodename, network_vid: "6670" })
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)

    # 09_client1_removed
    client1_removed_nodename = fixture_file_upload("nodenames/09_client1_removed.doc", "application/octet-stream")
    post(:create, { file: client1_removed_nodename, network_vid: "6670" })
    client1_index = expected_nodes.which_index(vid: "0x1a0e000c")
    expected_nodes.delete_at(client1_index)
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename")).sort_by_vid)
  end

  test "create with non empty Iplirconf" do
    # prepare Iplifconf and Coordinator
    Coordinator.destroy_all
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""
    nodenames_controller = @controller
    @controller = Api::V1::IplirconfsController.new
    changed_iplirconf = fixture_file_upload("iplirconfs/02_0x1a0e000a_changed.conf", "application/octet-stream")
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000a" })
    deleted_ip_iplirconf = fixture_file_upload("iplirconfs/06_0x1a0e000d_deleted_ip.conf", "application/octet-stream")
    post(:create, { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" })
    @controller = nodenames_controller
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""

    added_client1_nodename = fixture_file_upload("nodenames/01_added_client1.doc", "application/octet-stream")
    post(:create, { file: added_client1_nodename, network_vid: "6670" })
    expected_nodes = [
      {
        :vid => "0x1a0e000a",
        :name => "coordinator1",
        :enabled => true,
        :category => "server",
        :abonent_number => "0000",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.3\"]",
          :"0x1a0e000d" => "[\"192.0.2.3\"]",
        },
        :accessip => { :"0x1a0e000d" => "203.0.113.4" },
        :version => {
          :"0x1a0e000a" => "3.0-670",
          :"0x1a0e000d" => "3.0-670",
        },
      },
      {
        :vid => "0x1a0e000b",
        :name => "administrator",
        :enabled => true,
        :category => "client",
        :abonent_number => "0001",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.55\"]",
          :"0x1a0e000d" => "[\"192.0.2.55\"]",
        },
        :accessip => {
          :"0x1a0e000a" => "198.51.100.2",
          :"0x1a0e000d" => "203.0.113.2",
        },
        :version => {
          :"0x1a0e000a" => "3.2-673",
          :"0x1a0e000d" => "3.2-672",
        },
      },
      {
        :vid => "0x1a0e000c",
        :name => "client1",
        :enabled => true,
        :category => "client",
        :abonent_number => "0002",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.7\"]",
          :"0x1a0e000d" => "[\"192.0.2.7\"]",
        },
        :accessip => {
          :"0x1a0e000a" => "192.0.2.7",
          :"0x1a0e000d" => "203.0.113.3",
        },
        :version => {
          :"0x1a0e000a" => "0.3-2",
          :"0x1a0e000d" => "0.3-2",
        },
      },
    ]
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Nodename", "Iplirconf")).sort_by_vid)
  end
end
