require "test_helper"

class Api::V1::NodenamesControllerTest < ActionController::TestCase
  setup do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    Settings.networks_to_ignore = ""
  end

  test "correct token should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "incorrect token"
    post(:create)
    assert_response :unauthorized
  end

  test "file should be provided" do
    post(:create, params: { network_vid: "6670" })
    assert_equal("error", @response.body)
  end

  test "network_vid should be provided" do
    nodename_empty = fixture_file_upload(
      "nodenames/empty.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: nodename_empty })
    assert_equal("error", @response.body)
  end

  test "create" do
    Network.destroy_all

    # 00_initial (:add)
    initial_nodename = fixture_file_upload(
      "nodenames/00_initial.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: initial_nodename, network_vid: "6670" })
    network1 = Network.first
    expected_ncc_nodes = [
      {
        type: "CurrentNccNode",
        vid: "0x1a0e000a",
        name: "coordinator1",
        enabled: true,
        category: "server",
        abonent_number: "0000",
        server_number: "0001",
        creation_date: network1.last_nodenames_created_at,
        creation_date_accuracy: false,
        network_vid: "6670",
      },
      {
        type: "CurrentNccNode",
        vid: "0x1a0e000b",
        name: "administrator",
        enabled: true,
        category: "client",
        abonent_number: "0001",
        server_number: "0001",
        creation_date: network1.last_nodenames_created_at,
        creation_date_accuracy: false,
        network_vid: "6670",
      },
    ]
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 01_added_client1 (:add)
    added_client1_nodename = fixture_file_upload(
      "nodenames/01_added_client1.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: added_client1_nodename, network_vid: "6670" })
    expected_ncc_nodes.push({
      type: "CurrentNccNode",
      vid: "0x1a0e000c",
      name: "client1",
      enabled: true,
      category: "client",
      abonent_number: "0002",
      server_number: "0001",
      creation_date: network1.last_nodenames_created_at,
      creation_date_accuracy: true,
      network_vid: "6670",
    })
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 02_renamed_client1 (:change)
    renamed_client1_nodename = fixture_file_upload(
      "nodenames/02_renamed_client1.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: renamed_client1_nodename, network_vid: "6670" })
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" },
      {
        name: "client1-renamed1",
        enabled: false,
      }
    )
    expected_ncc_nodes.push({
      descendant_vid: "0x1a0e000c",
      name: "client1",
      enabled: true,
      creation_date: network1.last_nodenames_created_at,
    })
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 03_added_coordinator2 (:add)
    added_coordinator2_nodename = fixture_file_upload(
      "nodenames/03_added_coordinator2.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: added_coordinator2_nodename, network_vid: "6670" })
    expected_ncc_nodes.push(
      {
        type: "CurrentNccNode",
        vid: "0x1a0e000d",
        name: "coordinator2",
        enabled: true,
        category: "server",
        abonent_number: "0000",
        server_number: "0002",
        creation_date: network1.last_nodenames_created_at,
        creation_date_accuracy: true,
        network_vid: "6670",
      },
      {
        descendant_vid: "0x1a0e000c",
        enabled: false,
        creation_date: network1.last_nodenames_created_at,
      }
    )
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" }, { enabled: true })
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 04_client1_moved_to_coordinator2 (:change)
    client1_moved_to_coordinator2_nodename = fixture_file_upload(
      "nodenames/04_client1_moved_to_coordinator2.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: client1_moved_to_coordinator2_nodename, network_vid: "6670" })
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" },
      {
        abonent_number: "0001",
        server_number: "0002",
      }
    )
    expected_ncc_nodes.push(
      {
        descendant_vid: "0x1a0e000c",
        abonent_number: "0002",
        server_number: "0001",
        creation_date: network1.last_nodenames_created_at,
      }
    )
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 05_client1_disabled (:change)
    client1_disabled_nodename = fixture_file_upload(
      "nodenames/05_client1_disabled.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: client1_disabled_nodename, network_vid: "6670" })
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" }, { enabled: false })
    expected_ncc_nodes.push(
      {
        descendant_vid: "0x1a0e000c",
        enabled: true,
        creation_date: network1.last_nodenames_created_at,
      }
    )
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 06_added_node_from_ignoring_network
    # (Nothing should change.)
    Settings.networks_to_ignore = "6671"
    added_node_from_ignoring_network_nodename = fixture_file_upload(
      "nodenames/06_added_node_from_ignoring_network.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: added_node_from_ignoring_network_nodename, network_vid: "6670" })
    assert_ncc_nodes_should_be expected_ncc_nodes
    Settings.networks_to_ignore = ""

    # 07_added_internetworking_node_from_network_we_admin
    # (Nothing should change.)
    # "network we admin" is network for such we have Nodename.
    # "first_network_we_admin" = Network.find_by(network_vid: "6670")
    another_network_we_admin = Network.new(network_vid: "6672")
    another_network_we_admin.save!
    Nodename.push(hash: {}, belongs_to: another_network_we_admin)
    added_internetworking_node_we_admins_nodename = fixture_file_upload(
      "nodenames/07_added_internetworking_node_we_admins.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: added_internetworking_node_we_admins_nodename, network_vid: "6670" })
    assert_ncc_nodes_should_be expected_ncc_nodes

    # Cleaning up.
    another_network_we_admin.destroy
    Nodename.thread(another_network_we_admin).destroy_all

    # 08_group_changed
    # ("group" isn't in NccNode.props_from_nodename, so there souldn't be any changes.)
    group_changed_nodename = fixture_file_upload(
      "nodenames/08_group_changed.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: group_changed_nodename, network_vid: "6670" })
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 09_client1_removed (:remove)
    client1_removed_nodename = fixture_file_upload(
      "nodenames/09_client1_removed.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: client1_removed_nodename, network_vid: "6670" })
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" },
      {
        type: "DeletedNccNode",
        deletion_date: network1.last_nodenames_created_at,
      }
    )
    assert_ncc_nodes_should_be expected_ncc_nodes

    # restore 0x1a0e000c client1
    restore_client1_nodename = fixture_file_upload(
      "nodenames/08_group_changed.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: restore_client1_nodename, network_vid: "6670" })
    expected_ncc_nodes.change_where({ vid: "0x1a0e000c" },
      {
        type: "CurrentNccNode",
        deletion_date: nil,
      }
    )
    expected_ncc_nodes.reject_nil_keys
    assert_ncc_nodes_should_be expected_ncc_nodes

    # 10_added_internetworking_node
    added_internetworking_node_nodename = fixture_file_upload(
      "nodenames/10_added_internetworking_node.doc",
      "application/octet-stream"
    )
    post(:create, params: { file: added_internetworking_node_nodename, network_vid: "6670" })
    expected_ncc_nodes.push({
      type: "CurrentNccNode",
      vid: "0x1a0f000d",
      name: "3rd-party",
      enabled: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
      creation_date: network1.last_nodenames_created_at,
      creation_date_accuracy: true,
      network_vid: "6671",
    })
    assert_ncc_nodes_should_be expected_ncc_nodes
  end
end
