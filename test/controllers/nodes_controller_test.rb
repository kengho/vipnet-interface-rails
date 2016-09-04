class NodesControllerTest < ActionController::TestCase
  setup do
    @session = UserSession.create(users(:user1))
    @network = networks(:network1)
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

  test "shouldn't treat empty params as .*" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get(:index, { vid: "0x1a0e0001", name: "" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by many params using AND logic" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Alex1", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "Alex2", network: @network)
    CurrentNode.create!(vid: "0x1a0e0010", name: "Alex", network: @network)
    get(:index, { vid: "0x1a0e000", name: "Alex" })
    assert_equal(["0x1a0e0001", "0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search by vid" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    get(:index, { vid: "0x1a0e0002" })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search by abnormal vids" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    get(:index, { vid: "1A0E0002" })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search by part of vid" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    get(:index, { vid: "0002" })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search by range of vids" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    CurrentNode.create!(vid: "0x1a0e0003", network: @network)
    CurrentNode.create!(vid: "0x1a0e0004", network: @network)
    get(:index, { vid: "0x1a0e0001-0x1a0e0003" })
    assert_equal(["0x1a0e0001", "0x1a0e0002", "0x1a0e0003"], assigns["nodes"].vids)
  end

  test "shouldn't search by range when it's too large" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0100", network: @network)
    get(:index, { vid: "0x1a0e0001-0x1a0e0100" })
    assert_equal([], assigns["nodes"].vids)
  end

  test "should search by name" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get(:index, { name: "Alex" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by partial name" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get(:index, { name: "Al" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by name (case insensitive)" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Alex", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "John", network: @network)
    get(:index, { name: "alex" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search name and treat spaces like anything" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Marcus Forest", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "Wilbur Kelly Mallory", network: @network)
    get(:index, { name: "wil mal" })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search name using regexp" do
    CurrentNode.create!(vid: "0x1a0e0001", name: "Wilbur Kelly Mallory", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", name: "Kelly Wilbur Mallory", network: @network)
    get(:index, { name: "^wilbur\\s" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by ip" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: @network)
    node.save!
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    Ip.create!(u32: IPv4::u32("192.168.0.1"), node: node, coordinator: coordinators(:coordinator1))
    get(:index, { ip: "192.168.0.1" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by cidr" do
    node1 = CurrentNode.new(vid: "0x1a0e0001", network: @network)
    node2 = CurrentNode.new(vid: "0x1a0e0002", network: @network)
    node3 = CurrentNode.new(vid: "0x1a0e0003", network: @network)
    node1.save!
    node2.save!
    node3.save!
    Ip.create!(u32: IPv4::u32("192.168.0.0"), node: node1, coordinator: coordinators(:coordinator1))
    Ip.create!(u32: IPv4::u32("192.168.1.0"), node: node2, coordinator: coordinators(:coordinator1))
    Ip.create!(u32: IPv4::u32("192.168.0.255"), node: node3, coordinator: coordinators(:coordinator1))
    get(:index, { ip: "192.168.0.0/24" })
    assert_equal(["0x1a0e0001", "0x1a0e0003"], assigns["nodes"].vids)
  end

  test "should search by range" do
    node1 = CurrentNode.new(vid: "0x1a0e0001", network: @network)
    node2 = CurrentNode.new(vid: "0x1a0e0002", network: @network)
    node3 = CurrentNode.new(vid: "0x1a0e0003", network: @network)
    node1.save!
    node2.save!
    node3.save!
    Ip.create!(u32: IPv4::u32("192.168.0.0"), node: node1, coordinator: coordinators(:coordinator1))
    Ip.create!(u32: IPv4::u32("192.168.0.255"), node: node2, coordinator: coordinators(:coordinator1))
    Ip.create!(u32: IPv4::u32("192.168.0.254"), node: node3, coordinator: coordinators(:coordinator1))
    get(:index, { ip: "192.168.0.0-192.168.0.254" })
    assert_equal(["0x1a0e0001", "0x1a0e0003"], assigns["nodes"].vids)
  end

  test "shouldn't search by invalid ip" do
    get(:index, { ip: "invalid ip" })
    assert_equal([], assigns["nodes"].vids)
  end

  test "should search by version_decoded" do
    CurrentNode.create!(
      vid: "0x1a0e0001",
      version_decoded: {
        "0x1a0e000a" => "2.0",
        "0x1a0e000b" => "3.0",
      },
      network: @network
    )
    CurrentNode.create!(
      vid: "0x1a0e0002",
      version_decoded: {
        "0x1a0e000a" => "3.2",
        "0x1a0e000b" => "3.1",
      },
      network: @network
    )
    get(:index, { version_decoded: "3.1" })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "should search by version_decoded substring" do
    CurrentNode.create!(
      vid: "0x1a0e0001",
      version_decoded: {
        "0x1a0e000a" => "2.0",
        "0x1a0e000b" => "2.0",
      },
      network: @network
    )
    CurrentNode.create!(
      vid: "0x1a0e0002",
      version_decoded: {
        "0x1a0e000a" => "3.2",
        "0x1a0e000b" => "3.1",
      },
      network: @network
    )
    get(:index, { version_decoded: "3." })
    assert_equal(["0x1a0e0002"], assigns["nodes"].vids)
  end

  test "shouldn't treat underscore and percent as special symbols in version_decoded" do
    CurrentNode.create!(vid: "0x1a0e0001", version_decoded: { "0x1a0e000a" => "3.0" }, network: @network)
    get(:index, { version_decoded: "3_" })
    assert_equal([], assigns["nodes"].vids)
    get(:index, { version_decoded: "%3" })
    assert_equal([], assigns["nodes"].vids)
  end

  # temporarily implementations of DateTime search
  test "should search by creation_date (tmp)" do
    CurrentNode.create!(vid: "0x1a0e0001", creation_date: DateTime.new(2016, 9, 1), network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", creation_date: DateTime.new(2016, 9, 2), network: @network)
    get(:index, { creation_date: "2016-09-01" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by deletion_date (tmp)" do
    CurrentNode.create!(vid: "0x1a0e0001", deletion_date: DateTime.new(2016, 9, 1), network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", deletion_date: DateTime.new(2016, 9, 2), network: @network)
    get(:index, { deletion_date: "2016-09-01" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end
  # /temporarily implementations of DateTime search

  test "there are should be creation_date and deletion_date fields in nodes for where_date_like" do
    assert Node.column_names.include?("creation_date")
    assert Node.column_names.include?("deletion_date")
  end

  test "should search by ticket" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    Ticket.create!(ticket_system: @ticket_system2, vid: "0x1a0e0001", ticket_id: "2")
    get(:index, { ticket: "1" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end

  test "should search by ticket substring" do
    CurrentNode.create!(vid: "0x1a0e0001", network: @network)
    CurrentNode.create!(vid: "0x1a0e0002", network: @network)
    Ticket.create!(ticket_system: @ticket_system1, vid: "0x1a0e0001", ticket_id: "111")
    Ticket.create!(ticket_system: @ticket_system2, vid: "0x1a0e0001", ticket_id: "222")
    get(:index, { ticket: "11" })
    assert_equal(["0x1a0e0001"], assigns["nodes"].vids)
  end
end
