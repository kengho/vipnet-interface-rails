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
    Nodename.destroy_all
    Iplirconf.destroy_all
    Coordinator.destroy_all
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
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

    # 01_added_0x1a0e000d
    added_0x1a0e000d_iplirconf = fixture_file_upload("iplirconfs/01_added_0x1a0e000d.conf", "application/octet-stream")
    post(:create, { file: added_0x1a0e000d_iplirconf, coord_vid: "0x1a0e000a" })
    coordinator2_index = expected_nodes.which_index(vid: "0x1a0e000d")
    expected_nodes[coordinator2_index] = {
      :vid => "0x1a0e000d",
      :ip => { :"0x1a0e000a" => "[\"192.0.2.9\", \"192.0.2.10\"]" },
      :accessip => { :"0x1a0e000a" => "198.51.100.4" },
      :version => { :"0x1a0e000a" => "3.0-670" },
    }
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

    # 02_changed_client1_and_administrator
    # 0x1a0e000b administrator "ip= 192.0.2.5" => "ip= 192.0.2.55"
    # 0x1a0e000b administrator "version= 3.2-672" => "version= 3.2-673"
    # 0x1a0e000c client1 "accessip= 198.51.100.3" => "accessip= 192.0.2.7"
    changed_iplirconf = fixture_file_upload("iplirconfs/02_0x1a0e000a_changed.conf", "application/octet-stream")
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000a" })
    administrator_index = expected_nodes.which_index(vid: "0x1a0e000b")
    client1_index = expected_nodes.which_index(vid: "0x1a0e000c")
    expected_nodes[administrator_index][:ip] = { :"0x1a0e000a" => "[\"192.0.2.55\"]" }
    expected_nodes[administrator_index][:version] = { :"0x1a0e000a" => "3.2-673" }
    expected_nodes[client1_index][:accessip] = { :"0x1a0e000a" => "192.0.2.7" }
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

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
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

    # 04_0x1a0e000d_changed
    # 0x1a0e000a coordinator1 "ip= 192.0.2.1" => "ip= 192.0.2.51"
    # 0x1a0e000b administrator "version= 3.2-673" => "version= 3.2-672"
    changed_iplirconf = fixture_file_upload("iplirconfs/04_0x1a0e000d_changed.conf", "application/octet-stream")
    post(:create, { file: changed_iplirconf, coord_vid: "0x1a0e000d" })
    coordinator1_index = expected_nodes.which_index(vid: "0x1a0e000a")
    administrator_index = expected_nodes.which_index(vid: "0x1a0e000b")
    expected_nodes[coordinator1_index][:ip][:"0x1a0e000d"] = "[\"192.0.2.51\", \"192.0.2.3\"]"
    expected_nodes[administrator_index][:version][:"0x1a0e000d"] = "3.2-672"
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

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
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)

    # 06_0x1a0e000d_deleted_ip
    # 0x1a0e000a coordinator1 "deleted ip= 192.0.2.51"
    deleted_ip_iplirconf = fixture_file_upload("iplirconfs/06_0x1a0e000d_deleted_ip.conf", "application/octet-stream")
    post(:create, { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" })
    coordinator1_index = expected_nodes.which_index(vid: "0x1a0e000a")
    expected_nodes[coordinator1_index][:ip][:"0x1a0e000d"] = "[\"192.0.2.3\"]"
    assert_equal(expected_nodes.sort_by_vid, eval(Node.to_json_for("Iplirconf")).sort_by_vid)
  end
end
