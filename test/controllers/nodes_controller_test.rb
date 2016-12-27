require "test_helper"

class NodesControllerTest < ActionController::TestCase
  setup do
    @session = UserSession.create(users(:user1))
    @network = networks(:network1)
    @coordinator1 = coordinators(:coordinator1)
    @coordinator2 = coordinators(:coordinator2)
    @ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    @ticket_system2 = TicketSystem.create!(url_template: "http://tickets2.org/ticket_id={id}")
    Settings.vid_search_threshold = "0xff".to_i(16)
  end

  test "shouldn't be available without login" do
    @session.destroy
    get :index
    assert_response :redirect
  end

  test "should be available by user role" do
    get :index
    assert_response :success
  end

  test "should search by vid" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", network: @network)
    get_js(:load, { vid: "0x1a0e0002"})
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should search by abnormal vids" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", network: @network)
    get_js(:load, { vid: "1A0E0002" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should search by part of vid" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", network: @network)
    get_js(:load, { vid: "0002" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should search by range of vids" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0003", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0004", network: @network)
    get_js(:load, { vid: "0x1a0e0001-0x1a0e0003" })
    assert_equal(["0x1a0e0001", "0x1a0e0002", "0x1a0e0003"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't search by range when it's too large" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0100", network: @network)
    get_js(:load, { vid: "0x1a0e0001-0x1a0e0100" })
    assert_equal([], assigns["ncc_nodes"].vids)
  end

  test "should search by name" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get_js(:load, { name: "Alex" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by partial name" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get_js(:load, { name: "Al" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by name (case insensitive)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get_js(:load, { name: "alex" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search name and treat spaces like anything" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Marcus Forest", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Wilbur Kelly Mallory", network: @network)
    get_js(:load, { name: "wil mal" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should be able to use quotes for accurate search for name" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Marcus Kelly Forest", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Marcus Forest", network: @network)
    get_js(:load, { name: "\"marcus forest\"" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should search name using regexp" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Wilbur Kelly Mallory", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Kelly Wilbur Mallory", network: @network)
    get_js(:load, { name: "^wilbur\\s" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by ip" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    hw_node1 = CurrentHwNode.new(ncc_node: ncc_node1, coordinator: @coordinator1); hw_node1.save!
    hw_node2 = CurrentHwNode.new(ncc_node: ncc_node2, coordinator: @coordinator1); hw_node2.save!
    NodeIp.create!(hw_node: hw_node1, u32: IPv4::u32("192.168.0.1"))
    NodeIp.create!(hw_node: hw_node2, u32: IPv4::u32("192.168.0.2"))
    get_js(:load, { ip: "192.168.0.1" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by cidr" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    ncc_node3 = CurrentNccNode.new(vid: "0x1a0e0003", network: @network); ncc_node3.save!
    hw_node1 = CurrentHwNode.new(ncc_node: ncc_node1, coordinator: @coordinator1); hw_node1.save!
    hw_node2 = CurrentHwNode.new(ncc_node: ncc_node2, coordinator: @coordinator1); hw_node2.save!
    hw_node3 = CurrentHwNode.new(ncc_node: ncc_node3, coordinator: @coordinator1); hw_node3.save!
    NodeIp.create!(hw_node: hw_node1, u32: IPv4::u32("192.168.0.1"))
    NodeIp.create!(hw_node: hw_node2, u32: IPv4::u32("192.168.1.0"))
    NodeIp.create!(hw_node: hw_node3, u32: IPv4::u32("192.168.0.255"))
    get_js(:load, { ip: "192.168.0.0/24" })
    assert_equal(["0x1a0e0001", "0x1a0e0003"], assigns["ncc_nodes"].vids)
  end

  test "should search by range" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    ncc_node3 = CurrentNccNode.new(vid: "0x1a0e0003", network: @network); ncc_node3.save!
    hw_node1 = CurrentHwNode.new(ncc_node: ncc_node1, coordinator: @coordinator1); hw_node1.save!
    hw_node2 = CurrentHwNode.new(ncc_node: ncc_node2, coordinator: @coordinator1); hw_node2.save!
    hw_node3 = CurrentHwNode.new(ncc_node: ncc_node3, coordinator: @coordinator1); hw_node3.save!
    NodeIp.create!(hw_node: hw_node1, u32: IPv4::u32("192.168.0.1"))
    NodeIp.create!(hw_node: hw_node2, u32: IPv4::u32("192.168.0.255"))
    NodeIp.create!(hw_node: hw_node3, u32: IPv4::u32("192.168.0.254"))
    get_js(:load, { ip: "192.168.0.0-192.168.0.254" })
    assert_equal(["0x1a0e0001", "0x1a0e0003"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't search by invalid ip" do
    get_js(:load, { ip: "invalid ip" })
    assert_equal([], assigns["ncc_nodes"].vids)
  end

  test "should search by version_decoded" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator1,
      version_decoded: "2.0",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator2,
      version_decoded: "3.0",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator1,
      version_decoded: "3.1",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator2,
      version_decoded: "3.2",
    )
    get_js(:load, { version_decoded: "3.1" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should search by version_decoded substring" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator1,
      version_decoded: "2.0",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator2,
      version_decoded: "2.1",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator1,
      version_decoded: "3.1",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator2,
      version_decoded: "3.2",
    )
    get_js(:load, { version_decoded: "3." })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't treat underscore and percent as special symbols in version_decoded" do
    ncc_node = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node,
      coordinator: @coordinator1,
      version_decoded: "3.0",
    )
    get_js(:load, { version_decoded: "3_" })
    assert_equal([], assigns["ncc_nodes"].vids)
    get_js(:load, { version_decoded: "%3" })
    assert_equal([], assigns["ncc_nodes"].vids)
  end

  # temporarily implementations of DateTime search
  test "should search by creation_date (tmp)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", creation_date: DateTime.new(2016, 9, 1), network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", creation_date: DateTime.new(2016, 9, 2), network: @network)
    get_js(:load, { creation_date: "2016-09-01" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by deletion_date (tmp)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", deletion_date: DateTime.new(2016, 9, 1), network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", deletion_date: DateTime.new(2016, 9, 2), network: @network)
    get_js(:load, { deletion_date: "2016-09-01" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end
  # /temporarily implementations of DateTime search

  test "should search by ticket" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    Ticket.create!(
      ticket_system: @ticket_system1,
      ncc_node: ncc_node1,
      vid: "0x1a0e0001",
      ticket_id: "1",
    )
    Ticket.create!(
      ticket_system: @ticket_system2,
      ncc_node: ncc_node1,
      vid: "0x1a0e0001",
      ticket_id: "2",
    )
    get_js(:load, { ticket: "1" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by ticket substring" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    Ticket.create!(
      ticket_system: @ticket_system1,
      ncc_node: ncc_node1,
      vid: "0x1a0e0001",
      ticket_id: "111",
    )
    Ticket.create!(
      ticket_system: @ticket_system2,
      ncc_node: ncc_node1,
      vid: "0x1a0e0001",
      ticket_id: "222",
    )
    get_js(:load, { ticket: "11" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by mftp_server_vid" do
    CurrentNccNode.create!(
      vid: "0x1a0e0001",
      network: @network,
      server_number: "0001",
      category: "client",
    )
    CurrentNccNode.create!(
      vid: "0x1a0e0002",
      network: @network,
      server_number: "0002",
      category: "client",
    )
    CurrentNccNode.create!(
      vid: "0x1a0e0003",
      network: networks(:network2),
      server_number: "0001",
      category: "client",
    )
    CurrentNccNode.create!(
      vid: "0x1a0e0004",
      network: @network,
      server_number: "0001",
      category: "client",
    )
    CurrentNccNode.create!(
      vid: "0x1a0e000a",
      network: @network,
      server_number: "0001",
      category: "server",
    )
    get_js(:load, { mftp_server_vid: "0x1a0e000a" })
    assert_equal(["0x1a0e0001", "0x1a0e0004"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't treat empty params as .*" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get_js(:load, { vid: "0x1a0e0001", name: "" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search by many params using AND logic" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex1", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Alex2", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0010", name: "Alex", network: @network)
    get_js(:load, { vid: "0x1a0e000", name: "Alex" })
    assert_equal(["0x1a0e0001", "0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should do quick search by name" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get_js(:load, { search: "0x1a0e0001" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should do quick search by ip" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    ncc_node3 = CurrentNccNode.new(vid: "0x1a0e0003", network: @network); ncc_node3.save!
    hw_node1 = CurrentHwNode.new(ncc_node: ncc_node1, coordinator: @coordinator1); hw_node1.save!
    hw_node2 = CurrentHwNode.new(ncc_node: ncc_node2, coordinator: @coordinator1); hw_node2.save!
    hw_node3 = CurrentHwNode.new(ncc_node: ncc_node3, coordinator: @coordinator1); hw_node3.save!
    NodeIp.create!(hw_node: hw_node1, u32: IPv4::u32("192.168.0.1"))
    NodeIp.create!(hw_node: hw_node2, u32: IPv4::u32("192.168.0.255"))
    NodeIp.create!(hw_node: hw_node3, u32: IPv4::u32("192.168.0.254"))
    get_js(:load, { search: "192.168.0.1-192.168.0.254" })
    assert_equal(["0x1a0e0001", "0x1a0e0003"], assigns["ncc_nodes"].vids)
  end

  test "should search through DeletedNccNode if there are no such CurrentNccNode" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    DeletedNccNode.create!(vid: "0x1a0e0002", name: "Brad", network: @network)
    get_js(:load, { name: "Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't search through DeletedNccNode if there are such CurrentNccNode" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    DeletedNccNode.create!(vid: "0x1a0e0002", name: "Alex", network: @network)
    get_js(:load, { name: "Alex" })
    assert_equal(["0x1a0e0001"], assigns["ncc_nodes"].vids)
  end

  test "should search through DeletedNccNode in quick search" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    DeletedNccNode.create!(vid: "0x1a0e0002", name: "Brad", network: @network)
    get_js(:load, { search: "Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "shouldn't search by mftp_server_vid if mftp_server_vid doesn't belongs to coordinator" do
    CurrentNccNode.create!(
      vid: "0x1a0e0001",
      network: @network,
      server_number: "0001",
      category: "client",
    )
    CurrentNccNode.create!(
      vid: "0x1a0e0002",
      network: @network,
      server_number: "0001",
      category: "client",
    )
    get_js(:load, { mftp_server_vid: "0x1a0e0001" })
    assert_equal([], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (single param)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Brad", network: @network)
    get_js(:load, { search: "name:Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (single param with spaces)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Brad", network: @network)
    get_js(:load, { search: "name: Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (multiple params)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Brad1", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0013", name: "Brad2", network: @network)
    get_js(:load, { search: "id:0x1a0e000,name:Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (multiple params with spaces)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", name: "Brad1", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0013", name: "Brad2", network: @network)
    get_js(:load, { search: "id: 0x1a0e000, name: Brad" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (multiple ids)" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0002", network: @network)
    CurrentNccNode.create!(vid: "0x1a0e0003", network: @network)
    get_js(:load, { search: "ids: 0x1a0e0002, 0x1a0e0003" })
    assert_equal(["0x1a0e0002", "0x1a0e0003"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (version, ver)" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator1,
      version_decoded: "2.0",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator2,
      version_decoded: "3.0",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator1,
      version_decoded: "3.1",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator2,
      version_decoded: "3.2",
    )
    get_js(:load, { search: "version: 3.1" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
    get_js(:load, { search: "ver: 3.1" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end

  test "should parse 'search' param to perform custom search (version_hw, ver_hw)" do
    ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network); ncc_node1.save!
    ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0002", network: @network); ncc_node2.save!
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator1,
      version: "3.0-670",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node1,
      coordinator: @coordinator2,
      version: "3.2-672",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator1,
      version: "0.3-2",
    )
    CurrentHwNode.create!(
      ncc_node: ncc_node2,
      coordinator: @coordinator2,
      version: "4.20-0",
    )
    get_js(:load, { search: "version_hw: 0.3-2" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
    get_js(:load, { search: "ver_hw: 0.3-2" })
    assert_equal(["0x1a0e0002"], assigns["ncc_nodes"].vids)
  end
end
