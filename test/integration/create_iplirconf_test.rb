require "test_helper"

class CreateIplirconfTest < ActionDispatch::IntegrationTest
  setup do
    # Prepare configuration, where there are
    # "0x1a0e000a coordinator1",
    # "0x1a0e000b administrator",
    # "0x1a0e000c client1",
    # "0x1a0e000d coordinator2".
    Settings.networks_to_ignore = ""
    Nodename.destroy_all
    Iplirconf.destroy_all
    Coordinator.destroy_all
    added_coordinator2_nodename = fixture_file_upload(
      "nodenames/03_added_coordinator2.doc",
      "application/octet-stream",
    )
    post(
      api_v1_nodenames_url,
      params: { file: added_coordinator2_nodename, network_vid: "6670" },
      headers: { "HTTP_AUTHORIZATION" => "Token token=\"POST_ADMINISTRATOR_TOKEN\"" },
    )

    @headers = { "HTTP_AUTHORIZATION" => "Token token=\"POST_HW_TOKEN\"" }
  end

  test "create" do
    # Upload iplirconf with administrator, client1 and coordinator1 (:add).
    initial_iplirconf = fixture_file_upload(
      "iplirconfs/00_0x1a0e000a_initial.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: initial_iplirconf, coord_vid: "0x1a0e000a" },
      headers: @headers,
    )
    assert_equal(Api::V1::BaseController::OK_RESPONSE, @response.body)
    coordinator1 = Coordinator.find_by(vid: "0x1a0e000a")
    expected_hw_nodes = [
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000a",
        version: "3.0-670",
        version_decoded: HwNode.decode_version("3.0-670"),
        creation_date: coordinator1.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.1"),
          },
          {
            u32: IPv4.u32("192.0.2.3"),
          },
        ],
      },
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000b",
        accessip: "198.51.100.2",
        version: "3.2-672",
        version_decoded: HwNode.decode_version("3.2-672"),
        creation_date: coordinator1.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.5"),
          },
        ],
      },
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000c",
        accessip: "198.51.100.3",
        version: "0.3-2",
        version_decoded: HwNode.decode_version("0.3-2"),
        creation_date: coordinator1.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.7"),
          },
        ],
      },
    ]
    assert_hw_nodes_should_be expected_hw_nodes

    # 01_added_0x1a0e000d (:add)
    added_0x1a0e000d_iplirconf = fixture_file_upload(
      "iplirconfs/01_added_0x1a0e000d.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: added_0x1a0e000d_iplirconf, coord_vid: "0x1a0e000a" },
      headers: @headers,
    )
    expected_hw_nodes.push(
      type: "CurrentHwNode",
      coord_vid: "0x1a0e000a",
      ncc_node_vid: "0x1a0e000d",
      accessip: "198.51.100.4",
      version: "3.0-670",
      version_decoded: HwNode.decode_version("3.0-670"),
      creation_date: coordinator1.last_iplirconfs_created_at,
      node_ips: [
        {
          u32: IPv4.u32("192.0.2.9"),
        },
        {
          u32: IPv4.u32("192.0.2.10"),
        },
      ],
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 02_changed_client1_and_administrator
    # (:change accessip, :add ip, :remove ip)
    # 0x1a0e000b administrator "ip= 192.0.2.5" => "ip= 192.0.2.55"
    # 0x1a0e000b administrator "version= 3.2-672" => "version= 3.2-673"
    # 0x1a0e000c client1 "accessip= 198.51.100.3" => "accessip= 192.0.2.7"
    changed_iplirconf = fixture_file_upload(
      "iplirconfs/02_0x1a0e000a_changed.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: changed_iplirconf, coord_vid: "0x1a0e000a" },
      headers: @headers,
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000b",
      },
      {
        version: "3.2-673",
        version_decoded: HwNode.decode_version("3.2-673"),
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.55"),
          },
        ],
      },
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000c",
      },
      {
        accessip: "192.0.2.7",
      },
    )
    expected_hw_nodes.push(
      {
        descendant_coord_vid: "0x1a0e000a",
        descendant_vid: "0x1a0e000c",
        accessip: "198.51.100.3",
        creation_date: coordinator1.last_iplirconfs_created_at,
      },
      {
        descendant_coord_vid: "0x1a0e000a",
        descendant_vid: "0x1a0e000b",
        version: "3.2-672",
        version_decoded: HwNode.decode_version("3.2-672"),
        creation_date: coordinator1.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.5"),
          },
        ],
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 03_0x1a0e000d_initial (:add)
    coordinator2_initial_iplirconf = fixture_file_upload(
      "iplirconfs/03_0x1a0e000d_initial.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: coordinator2_initial_iplirconf, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    coordinator2 = Coordinator.find_by(vid: "0x1a0e000d")
    expected_hw_nodes.push(
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000a",
        accessip: "203.0.113.4",
        version: "3.0-670",
        version_decoded: HwNode.decode_version("3.0-670"),
        creation_date: coordinator2.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.1"),
          },
          {
            u32: IPv4.u32("192.0.2.3"),
          },
        ],
      },
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000b",
        accessip: "203.0.113.2",
        version: "3.2-673",
        version_decoded: HwNode.decode_version("3.2-673"),
        creation_date: coordinator2.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.55"),
          },
        ],
      },
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000c",
        accessip: "203.0.113.3",
        version: "0.3-2",
        version_decoded: HwNode.decode_version("0.3-2"),
        creation_date: coordinator2.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.7"),
          },
        ],
      },
      {
        type: "CurrentHwNode",
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000d",
        version: "3.0-670",
        version_decoded: HwNode.decode_version("3.0-670"),
        creation_date: coordinator2.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.9"),
          },
          {
            u32: IPv4.u32("192.0.2.10"),
          },
        ],
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 04_0x1a0e000d_changed (:change, :add, :remove)
    # 0x1a0e000a coordinator1 "ip= 192.0.2.1" => "ip= 192.0.2.51"
    # 0x1a0e000b administrator "version= 3.2-673" => "version= 3.2-672"
    changed_iplirconf = fixture_file_upload(
      "iplirconfs/04_0x1a0e000d_changed.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: changed_iplirconf, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000b",
      },
      {
        version: "3.2-672",
        version_decoded: HwNode.decode_version("3.2-672"),
      },
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000a",
      },
      {
        # "deep_merge" in "change_where" deletes "192.0.2.3"
        # if not present here.
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.3"),
          },
          {
            u32: IPv4.u32("192.0.2.51"),
          },
        ],
      },
    )
    expected_hw_nodes.push(
      {
        descendant_coord_vid: "0x1a0e000d",
        descendant_vid: "0x1a0e000b",
        version: "3.2-673",
        version_decoded: HwNode.decode_version("3.2-673"),
        creation_date: coordinator2.last_iplirconfs_created_at,
      },
      {
        descendant_coord_vid: "0x1a0e000d",
        descendant_vid: "0x1a0e000a",
        creation_date: coordinator2.last_iplirconfs_created_at,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.1"),
          },
        ],
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 05_0x1a0e000d_added_new_client (:add)
    ncc_node_0x1a0e000e = CurrentNccNode.new(vid: "0x1a0e000e", network: networks(:network1))
    ncc_node_0x1a0e000e.save!
    added_new_client_iplirconf = fixture_file_upload(
      "iplirconfs/05_0x1a0e000d_added_new_client.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: added_new_client_iplirconf, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    expected_hw_nodes.push(
      type: "CurrentHwNode",
      coord_vid: "0x1a0e000d",
      ncc_node_vid: "0x1a0e000e",
      creation_date: coordinator2.last_iplirconfs_created_at,
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 06_0x1a0e000d_deleted_ip (:remove)
    # 0x1a0e000a coordinator1 "deleted ip= 192.0.2.51"
    deleted_ip_iplirconf = fixture_file_upload(
      "iplirconfs/06_0x1a0e000d_deleted_ip.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    expected_hw_nodes.push(
      descendant_coord_vid: "0x1a0e000d",
      descendant_vid: "0x1a0e000a",
      creation_date: coordinator2.last_iplirconfs_created_at,
      node_ips: [
        {
          u32: IPv4.u32("192.0.2.51"),
        },
      ],
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000a",
      },
      {
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.3"),
          },
        ],
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 07_0x1a0e000d_deleted_client1 (:remove)
    # 0x1a0e000c client1 "deleted section"
    deleted_client1 = fixture_file_upload(
      "iplirconfs/07_0x1a0e000d_deleted_client1.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: deleted_client1, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000c",
      },
      {
        type: "DeletedHwNode",
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 08_0x1a0e000d_restored_client1 (:add)
    restored_client1 = fixture_file_upload(
      "iplirconfs/08_0x1a0e000d_restored_client1.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: restored_client1, coord_vid: "0x1a0e000d" },
      headers: @headers,
    )
    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000d",
        ncc_node_vid: "0x1a0e000c",
      },
      {
        type: "CurrentHwNode",
        accessip: "203.0.113.5",
        version: nil,
        version_decoded: nil,
        node_ips: [
          {
            u32: IPv4.u32("192.0.2.18"),
          },
        ],
      },
    )
    expected_hw_nodes.push(
      descendant_coord_vid: "0x1a0e000d",
      descendant_vid: "0x1a0e000c",
      accessip: "203.0.113.3",
      version: "0.3-2",
      version_decoded: HwNode.decode_version("0.3-2"),
      creation_date: coordinator2.last_iplirconfs_created_at,
      node_ips: [
        {
          u32: IPv4.u32("192.0.2.7"),
        },
      ],
    )
    expected_hw_nodes.reject_nil_keys
    assert_hw_nodes_should_be expected_hw_nodes

    # 09_0x1a0e000a_moved_to_v4 (nothing should change)
    moved_to_v4_iplifconf = fixture_file_upload(
      "iplirconfs/09_0x1a0e000a_moved_to_v4.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: moved_to_v4_iplifconf, coord_vid: "0x1a0e000a" },
      headers: @headers,
    )
    assert_hw_nodes_should_be expected_hw_nodes

    # 10_0x1a0e000a_changed (:change)
    iplifconf_v4_changed = fixture_file_upload(
      "iplirconfs/10_0x1a0e000a_changed.conf",
      "application/octet-stream",
    )
    post(
      api_v1_iplirconfs_url,
      params: { file: iplifconf_v4_changed, coord_vid: "0x1a0e000a" },
      headers: @headers,
    )

    expected_hw_nodes.change_where(
      {
        coord_vid: "0x1a0e000a",
        ncc_node_vid: "0x1a0e000c",
      },
      {
        version: "3.0-670",
        version_decoded: HwNode.decode_version("3.0-670"),
      },
    )
    expected_hw_nodes.push(
      descendant_coord_vid: "0x1a0e000a",
      descendant_vid: "0x1a0e000c",
      version: "0.3-2",
      version_decoded: HwNode.decode_version("0.3-2"),
      creation_date: coordinator1.last_iplirconfs_created_at,
    )
    assert_hw_nodes_should_be expected_hw_nodes
  end
end
