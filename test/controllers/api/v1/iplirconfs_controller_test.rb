# @TODO this is mess, use to_json(:include => :node_ips) or something related
require "test_helper"

class Api::V1::IplirconfsControllerTest < ActionController::TestCase
  setup do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""
  end

  test "correct token should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "incorrect token"
    post(:create)
    assert_response :unauthorized
  end

  test "file should be provided" do
    post(:create, { file: nil, coord_vid: "0x1a0e000a" })
    assert_equal("error", @response.body)
  end

  test "coord_vid should be provided" do
    iplirconf_empty = fixture_file_upload(
      "iplirconfs/empty.conf",
      "application/octet-stream"
    )
    post(:create, { file: iplirconf_empty, coord_vid: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    # prepare configuration, where there are
    # 0x1a0e000a coordinator1,
    # 0x1a0e000b administrator,
    # 0x1a0e000c client1,
    # 0x1a0e000d coordinator2
    Settings.networks_to_ignore = ""
    Nodename.destroy_all
    Iplirconf.destroy_all
    Coordinator.destroy_all
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    iplirconfs_controller = @controller
    @controller = Api::V1::NodenamesController.new
    added_coordinator2_nodename = fixture_file_upload(
      "nodenames/03_added_coordinator2.doc",
      "application/octet-stream"
    )
    post(:create, { file: added_coordinator2_nodename, network_vid: "6670" })
    @controller = iplirconfs_controller
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""
    ncc_node_0x1a0e000a = CurrentNccNode.find_by(vid: "0x1a0e000a")
    ncc_node_0x1a0e000b = CurrentNccNode.find_by(vid: "0x1a0e000b")
    ncc_node_0x1a0e000c = CurrentNccNode.find_by(vid: "0x1a0e000c")
    ncc_node_0x1a0e000d = CurrentNccNode.find_by(vid: "0x1a0e000d")

    # upload iplirconf with administrator, client1 and coordinator1 (:add)
    initial_iplirconf = fixture_file_upload(
      "iplirconfs/00_0x1a0e000a_initial.conf",
      "application/octet-stream"
    )
    post(:create, { file: initial_iplirconf, coord_vid: "0x1a0e000a" })
    coordinator_0x1a0e000a = Coordinator.find_by(vid: "0x1a0e000a")
    assert_equal(Api::V1::BaseController::OK_RESPONSE, @response.body)
    expected_hw_nodes = [
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :version => "3.0-670",
        :version_decoded => HwNode.decode_version("3.0-670"),
        :accessip => nil,
      },
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :accessip => "198.51.100.2",
        :version => "3.2-672",
        :version_decoded => HwNode.decode_version("3.2-672"),
      },
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :accessip => "198.51.100.3",
        :version => "0.3-2",
        :version_decoded => HwNode.decode_version("0.3-2"),
      },
    ]
    expected_node_ips = [
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.3"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000b,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.5"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000c,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.7"),
      },
    ]
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips

    # 01_added_0x1a0e000d (:add)
    added_0x1a0e000d_iplirconf = fixture_file_upload(
      "iplirconfs/01_added_0x1a0e000d.conf",
      "application/octet-stream"
    )
    post(:create, { file: added_0x1a0e000d_iplirconf, coord_vid: "0x1a0e000a" })
    expected_hw_nodes.push({
      :type => "CurrentHwNode",
      :ncc_node_id => ncc_node_0x1a0e000d.id,
      :coordinator_id => coordinator_0x1a0e000a.id,
      :version => "3.0-670",
      :version_decoded => HwNode.decode_version("3.0-670"),
      :accessip => "198.51.100.4",
    })
    expected_node_ips.push(
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000d,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.9"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000d,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.10"),
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips

    # 02_changed_client1_and_administrator
    # (:change accessip, :add ip, :remove ip)
    # 0x1a0e000b administrator "ip= 192.0.2.5" => "ip= 192.0.2.55"
    # 0x1a0e000b administrator "version= 3.2-672" => "version= 3.2-673"
    # 0x1a0e000c client1 "accessip= 198.51.100.3" => "accessip= 192.0.2.7"
    changed_iplirconf = fixture_file_upload(
      "iplirconfs/02_0x1a0e000a_changed.conf",
      "application/octet-stream"
    )
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000a" })
    expected_hw_nodes.change_where(
      {
        :ncc_node_id => ncc_node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
      },
      {
        :version => "3.2-673",
        :version_decoded => HwNode.decode_version("3.2-673"),
      }
    )
    expected_hw_nodes.change_where(
      {
        :ncc_node_id => ncc_node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
      },
      { :accessip => "192.0.2.7" }
    )
    expected_node_ips.change_where(
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000b,
          coordinator: coordinator_0x1a0e000a,
        ).id,
        :u32 => IPv4::u32("192.0.2.5"),
      },
      { :u32 => IPv4::u32("192.0.2.55") }
    )
    expected_node_ips.push({
      :hw_node_id => HwNode.find_by(
        descendant: CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000b,
          coordinator: coordinator_0x1a0e000a,
        ),
        version: "3.2-672",
      ).id,
      :u32 => IPv4::u32("192.0.2.5"),
    })
    expected_hw_nodes_ascendants = [
      {
        descendant_type: "CurrentHwNode",
        descendant_coord_vid: "0x1a0e000a",
        descendant_vid: "0x1a0e000c",
        accessip: "198.51.100.3",
      },
      {
        descendant_type: "CurrentHwNode",
        descendant_coord_vid: "0x1a0e000a",
        descendant_vid: "0x1a0e000b",
        version: "3.2-672",
        version_decoded: HwNode.decode_version("3.2-672"),
      },
    ]
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 03_0x1a0e000d_initial (:add)
    coordinator2_initial_iplirconf = fixture_file_upload(
      "iplirconfs/03_0x1a0e000d_initial.conf",
      "application/octet-stream"
    )
    post(:create, { file: coordinator2_initial_iplirconf, coord_vid: "0x1a0e000d" })
    coordinator_0x1a0e000d = Coordinator.find_by(vid: "0x1a0e000d")
    expected_hw_nodes.push(
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :version => "3.0-670",
        :version_decoded => HwNode.decode_version("3.0-670"),
        :accessip => "203.0.113.4",
      },
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :version => "3.2-673",
        :version_decoded => HwNode.decode_version("3.2-673"),
        :accessip => "203.0.113.2",
      },
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :version => "0.3-2",
        :version_decoded => HwNode.decode_version("0.3-2"),
        :accessip => "203.0.113.3",
      },
      {
        :type => "CurrentHwNode",
        :ncc_node_id => ncc_node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :version => "3.0-670",
        :version_decoded => HwNode.decode_version("3.0-670"),
        :accessip => nil,
      },
    )
    expected_node_ips.push(
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.3"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000b,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.55"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000c,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.7"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000d,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.9"),
      },
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000d,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.10"),
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 04_0x1a0e000d_changed (:change, :add, :remove)
    # 0x1a0e000a coordinator1 "ip= 192.0.2.1" => "ip= 192.0.2.51"
    # 0x1a0e000b administrator "version= 3.2-673" => "version= 3.2-672"
    changed_iplirconf = fixture_file_upload(
      "iplirconfs/04_0x1a0e000d_changed.conf",
      "application/octet-stream"
    )
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000d" })
    expected_hw_nodes.change_where(
      {
        :ncc_node_id => ncc_node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
      },
      {
        :version => "3.2-672",
        :version_decoded => HwNode.decode_version("3.2-672"),
      }
    )
    expected_node_ips.change_where(
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      { :u32 => IPv4::u32("192.0.2.51") }
    )
    expected_node_ips.push({
      :hw_node_id => HwNode.find_by(
        descendant: CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000d,
        ),
      ).id,
      :u32 => IPv4::u32("192.0.2.1"),
    })
    expected_hw_nodes_ascendants.push(
      {
        descendant_type: "CurrentHwNode",
        descendant_coord_vid: "0x1a0e000d",
        descendant_vid: "0x1a0e000b",
        version: "3.2-673",
        version_decoded: HwNode.decode_version("3.2-673"),
      },
      {
        descendant_type: "CurrentHwNode",
        descendant_coord_vid: "0x1a0e000d",
        descendant_vid: "0x1a0e000a",
      },
    )
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 05_0x1a0e000d_added_new_client (:add)
    ncc_node_0x1a0e000e = CurrentNccNode.new(vid: "0x1a0e000e", network: networks(:network1))
    ncc_node_0x1a0e000e.save!
    added_new_client_iplirconf = fixture_file_upload(
      "iplirconfs/05_0x1a0e000d_added_new_client.conf",
      "application/octet-stream"
    )
    post(:create, { file: added_new_client_iplirconf, coord_vid: "0x1a0e000d" })
    expected_hw_nodes.push({
      :type => "CurrentHwNode",
      :ncc_node_id => ncc_node_0x1a0e000e.id,
      :coordinator_id => coordinator_0x1a0e000d.id,
      :version => nil,
      :version_decoded => nil,
      :accessip => nil,
    })
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 06_0x1a0e000d_deleted_ip (:remove)
    # 0x1a0e000a coordinator1 "deleted ip= 192.0.2.51"
    deleted_ip_iplirconf = fixture_file_upload(
      "iplirconfs/06_0x1a0e000d_deleted_ip.conf",
      "application/octet-stream"
    )
    post(:create, { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" })
    accendant_0x1a0e000d_0x1a0e000a_ip_51 = HwNode.joins(:node_ips).find_by("node_ips.u32": IPv4::u32("192.0.2.51"))
    expected_node_ips.change_where(
      {
        :hw_node_id => CurrentHwNode.find_by(
          ncc_node: ncc_node_0x1a0e000a,
          coordinator: coordinator_0x1a0e000d,
        ).id,
        :u32 => IPv4::u32("192.0.2.51"),
      },
      {
        :hw_node_id => accendant_0x1a0e000d_0x1a0e000a_ip_51.id,
      }
    )
    expected_hw_nodes_ascendants.push({
      descendant_type: "CurrentHwNode",
      descendant_coord_vid: "0x1a0e000d",
      descendant_vid: "0x1a0e000a",
    })
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 07_0x1a0e000d_deleted_client1 (:remove)
    # 0x1a0e000c client1 "deleted section"
    deleted_client1 = fixture_file_upload(
      "iplirconfs/07_0x1a0e000d_deleted_client1.conf",
      "application/octet-stream"
    )
    # where ip = 192.0.2.51
    hw_node_0x1a0e000d_0x1a0e000c_ip_7 = HwNode.joins(:node_ips).find_by("node_ips.u32": IPv4::u32("192.0.2.7"))
    post(:create, { file: deleted_client1, coord_vid: "0x1a0e000d" })
    accendant_0x1a0e000d_0x1a0e000c_ip_7 = HwNode.joins(:node_ips).find_by("node_ips.u32": IPv4::u32("192.0.2.7"))
    expected_hw_nodes.change_where(
      {
        :ncc_node_id => ncc_node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
      },
      { type: "DeletedHwNode" }
    )
    expected_node_ips.change_where(
      {
        :hw_node_id => hw_node_0x1a0e000d_0x1a0e000c_ip_7.id
      },
      {
        :hw_node_id => accendant_0x1a0e000d_0x1a0e000c_ip_7.id,
      }
    )
    expected_hw_nodes_ascendants.change_where(
      {
        descendant_type: "CurrentHwNode",
        descendant_vid: "0x1a0e000c",
        descendant_coord_vid: "0x1a0e000d",
      },
      {
        descendant_type: "DeletedHwNode",
      }
    )
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants

    # 08_0x1a0e000d_restored_client1 (:add)
    restored_client1 = fixture_file_upload(
      "iplirconfs/08_0x1a0e000d_restored_client1.conf",
      "application/octet-stream"
    )
    post(:create, { file: restored_client1, coord_vid: "0x1a0e000d" })
    expected_hw_nodes.change_where(
      {
        :ncc_node_id => ncc_node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
      },
      {
        type: "CurrentHwNode",
        accessip: "203.0.113.5",
        version: nil,
        version_decoded: HwNode.decode_version(nil),
      }
    )
    expected_node_ips.push(
      :hw_node_id => CurrentHwNode.find_by(
        ncc_node: ncc_node_0x1a0e000c,
        coordinator: coordinator_0x1a0e000d,
      ).id,
      :u32 => IPv4::u32("192.0.2.18"),
    )
    expected_hw_nodes_ascendants.change_where(
      {
        descendant_type: "DeletedHwNode",
        descendant_vid: "0x1a0e000c",
        descendant_coord_vid: "0x1a0e000d",
      },
      {
        descendant_type: "CurrentHwNode",
      }
    )
    expected_hw_nodes_ascendants.push({
      descendant_type: "CurrentHwNode",
      descendant_vid: "0x1a0e000c",
      descendant_coord_vid: "0x1a0e000d",
      accessip: "203.0.113.3",
      version: "0.3-2",
      version_decoded: HwNode.decode_version("0.3-2"),
    })
    assert_hw_nodes_should_be expected_hw_nodes
    assert_node_ips_should_be expected_node_ips
    assert_hw_nodes_ascendants_should_be expected_hw_nodes_ascendants
  end
end
