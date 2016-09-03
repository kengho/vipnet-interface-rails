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
    iplirconf_empty = fixture_file_upload("iplirconfs/empty.conf", "application/octet-stream")
    post(:create, { file: iplirconf_empty, coord_vid: nil })
    assert_equal("error", @response.body)
  end

  test "create" do
    # prepare configuration, where there are
    # 0x1a0e000a coordinator1,
    # 0x1a0e000b administrator,
    # 0x1a0e000c client1
    # 0x1a0e000d coordinator2
    Settings.networks_to_ignore = ""
    Nodename.destroy_all
    Iplirconf.destroy_all
    Coordinator.destroy_all
    NodeIp.destroy_all
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_ADMINISTRATOR_TOKEN\""
    iplirconfs_controller = @controller
    @controller = Api::V1::NodenamesController.new
    added_coordinator2_nodename = fixture_file_upload("nodenames/03_added_coordinator2.doc", "application/octet-stream")
    post(:create, { file: added_coordinator2_nodename, network_vid: "6670" })
    @controller = iplirconfs_controller
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""

    # upload iplirconf with administrator, client1 and coordinator1
    initial_iplirconf = fixture_file_upload("iplirconfs/00_0x1a0e000a_initial.conf", "application/octet-stream")
    post(:create, { file: initial_iplirconf, coord_vid: "0x1a0e000a" })
    assert_equal("ok", @response.body)
    expected_nodes = [
      {
        :vid => "0x1a0e000a",
        # for some reason,
        # eval({"a" => "b"}.to_json)
        # => {:a=>"b"}
        :ip => { :"0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.3\"]" },
        :accessip => {},
        :version => { :"0x1a0e000a" => "3.0-670" },
      },
      {
        :vid => "0x1a0e000b",
        :ip => { :"0x1a0e000a" => "[\"192.0.2.5\"]" },
        :accessip => { :"0x1a0e000a" => "198.51.100.2" },
        :version => { :"0x1a0e000a" => "3.2-672" },
      },
      {
        :vid => "0x1a0e000c",
        :ip => { :"0x1a0e000a" => "[\"192.0.2.7\"]" },
        :accessip => { :"0x1a0e000a" => "198.51.100.3" },
        :version => { :"0x1a0e000a" => "0.3-2" },
      },
      {
        :vid => "0x1a0e000d",
        :ip => {},
        :accessip => {},
        :version => {},
      },
    ]
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)

    node_0x1a0e000a = CurrentNode.find_by(vid: "0x1a0e000a")
    node_0x1a0e000b = CurrentNode.find_by(vid: "0x1a0e000b")
    node_0x1a0e000c = CurrentNode.find_by(vid: "0x1a0e000c")
    node_0x1a0e000d = CurrentNode.find_by(vid: "0x1a0e000d")
    coordinator_0x1a0e000a = Coordinator.find_by(vid: "0x1a0e000a")
    expected_ips = [
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.3"),
      },
      {
        :node_id => node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.5"),
      },
      {
        :node_id => node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.7"),
      },
    ]
    expected_accessips = [
      {
        :node_id => node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("198.51.100.2"),
      },
      {
        :node_id => node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("198.51.100.3"),
      },
    ]
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 01_added_0x1a0e000d
    added_0x1a0e000d_iplirconf = fixture_file_upload("iplirconfs/01_added_0x1a0e000d.conf", "application/octet-stream")
    post(:create, { file: added_0x1a0e000d_iplirconf, coord_vid: "0x1a0e000a" })
    expected_nodes.change_where({ :vid => "0x1a0e000d" },
      {
        :ip => { :"0x1a0e000a" => "[\"192.0.2.9\", \"192.0.2.10\"]" },
        :accessip => { :"0x1a0e000a" => "198.51.100.4" },
        :version => { :"0x1a0e000a" => "3.0-670" },
      }
    )
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

    expected_ips.push(
      {
        :node_id => node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.9"),
      },
      {
        :node_id => node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("192.0.2.10"),
      },
    )
    expected_accessips.push(
      {
        :node_id => node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000a.id,
        :u32 => IPv4::u32("198.51.100.4"),
      },
    )
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 02_changed_client1_and_administrator
    # 0x1a0e000b administrator "ip= 192.0.2.5" => "ip= 192.0.2.55"
    # 0x1a0e000b administrator "version= 3.2-672" => "version= 3.2-673"
    # 0x1a0e000c client1 "accessip= 198.51.100.3" => "accessip= 192.0.2.7"
    changed_iplirconf = fixture_file_upload("iplirconfs/02_0x1a0e000a_changed.conf", "application/octet-stream")
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000a" })
    expected_nodes.change_where({ :vid => "0x1a0e000b" },
      {
        :ip => { :"0x1a0e000a" => "[\"192.0.2.55\"]" },
        :version => { :"0x1a0e000a" => "3.2-673" },
      }
    )
    expected_nodes.change_where({ :vid => "0x1a0e000c" },
      { :accessip => { :"0x1a0e000a" => "192.0.2.7" }},
    )
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)

    expected_ips.change_where({ :node_id => node_0x1a0e000b.id, :coordinator_id => coordinator_0x1a0e000a.id },
      { :u32 => IPv4::u32("192.0.2.55") }
    )
    expected_accessips.change_where({ :node_id => node_0x1a0e000c.id, :coordinator_id => coordinator_0x1a0e000a.id },
      { :u32 => IPv4::u32("192.0.2.7") }
    )
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 03_0x1a0e000d_initial
    coordinator2_initial_iplirconf = fixture_file_upload("iplirconfs/03_0x1a0e000d_initial.conf", "application/octet-stream")
    post(:create, { file: coordinator2_initial_iplirconf, coord_vid: "0x1a0e000d" })
    expected_nodes = [
      {
        :vid => "0x1a0e000a",
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.3\"]",
          :"0x1a0e000d" => "[\"192.0.2.1\", \"192.0.2.3\"]",
        },
        :accessip => { :"0x1a0e000d" => "203.0.113.4" },
        :version => {
          :"0x1a0e000a" => "3.0-670",
          :"0x1a0e000d" => "3.0-670",
        },
      },
      {
        :vid => "0x1a0e000b",
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
          :"0x1a0e000d" => "3.2-673",
        },
      },
      {
        :vid => "0x1a0e000c",
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
      {
        :vid => "0x1a0e000d",
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.9\", \"192.0.2.10\"]",
          :"0x1a0e000d" => "[\"192.0.2.9\", \"192.0.2.10\"]",
        },
        :accessip => {
          :"0x1a0e000a" => "198.51.100.4",
        },
        :version => {
          :"0x1a0e000a" => "3.0-670",
          :"0x1a0e000d" => "3.0-670",
        },
      },
    ]
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)

    coordinator_0x1a0e000d = Coordinator.find_by(vid: "0x1a0e000d")
    expected_ips.push(
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.3"),
      },
      {
        :node_id => node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.55"),
      },
      {
        :node_id => node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.7"),
      },
      {
        :node_id => node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.9"),
      },
      {
        :node_id => node_0x1a0e000d.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.10"),
      },
    )
    expected_accessips.push(
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("203.0.113.4"),
      },
      {
        :node_id => node_0x1a0e000b.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("203.0.113.2"),
      },
      {
        :node_id => node_0x1a0e000c.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("203.0.113.3"),
      },
    )
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 04_0x1a0e000d_changed
    # 0x1a0e000a coordinator1 "ip= 192.0.2.1" => "ip= 192.0.2.51"
    # 0x1a0e000b administrator "version= 3.2-673" => "version= 3.2-672"
    changed_iplirconf = fixture_file_upload("iplirconfs/04_0x1a0e000d_changed.conf", "application/octet-stream")
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000d" })
    expected_nodes.change_where({ :vid => "0x1a0e000a" },
      { :ip => { :"0x1a0e000d" => "[\"192.0.2.51\", \"192.0.2.3\"]" }}
    )
    expected_nodes.change_where({ :vid => "0x1a0e000b" },
      { :version => { :"0x1a0e000d" => "3.2-672" }}
    )
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)

    expected_ips.change_where(
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.1"),
      },
      { :u32 => IPv4::u32("192.0.2.51") }
    )
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 05_0x1a0e000d_added_new_client
    CurrentNode.new(vid: "0x1a0e000e", name: "new_client", network: networks(:network1)).save!
    added_new_client_iplirconf = fixture_file_upload("iplirconfs/05_0x1a0e000d_added_new_client.conf", "application/octet-stream")
    post(:create, { file: added_new_client_iplirconf, coord_vid: "0x1a0e000d" })
    expected_nodes.push({
      :vid => "0x1a0e000e",
      :ip => {},
      :accessip => {},
      :version => {},
    })
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)

    # 06_0x1a0e000d_deleted_ip
    # 0x1a0e000a coordinator1 "deleted ip= 192.0.2.51"
    deleted_ip_iplirconf = fixture_file_upload("iplirconfs/06_0x1a0e000d_deleted_ip.conf", "application/octet-stream")
    post(:create, { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" })
    expected_nodes.change_where({ :vid => "0x1a0e000a" },
      { :ip => { :"0x1a0e000d" => "[\"192.0.2.3\"]" }}
    )
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Iplirconf")).sort_by_vid)

    expected_ips.change_where(
      {
        :node_id => node_0x1a0e000a.id,
        :coordinator_id => coordinator_0x1a0e000d.id,
        :u32 => IPv4::u32("192.0.2.51"),
      },
      nil
    )
    assert_equal(expected_ips.sort_by_node_coordinator_and_u32, eval(Ip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
    assert_equal(expected_accessips.sort_by_node_coordinator_and_u32, eval(Accessip.to_json_nonmagic).sort_by_node_coordinator_and_u32)
  end
end
