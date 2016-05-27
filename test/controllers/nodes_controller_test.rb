class NodesControllerTest < ActionController::TestCase
  test "available by user role" do
    user_session1 = UserSession.create(users(:user1))
    get :index
    assert_response :success
  end

  test "check params" do
    user_session1 = UserSession.create(users(:user1))
    node = Node.new(
      vipnet_id: "0xffffffff",
      name: "test",
      network_id: networks(:network1).id,
    )
    node.save!

    get :availability, node_id: node.id
    assert_response :success

    get :availability, node_id: "node don't exist"
    assert_response :bad_request

    get :history, node_id: node.id
    assert_response :success

    get :history, node_id: "node dont exist"
    assert_response :bad_request
  end

  test "search" do
    user_session1 = UserSession.create(users(:user1))
    Node.destroy_all
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client0x1a0e0001--new",
      network_id: networks(:network1).id,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client0x1a0e0001--old1_1",
      network_id: networks(:network1).id,
      history: true,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client0x1a0e0001--old1_2",
      network_id: networks(:network1).id,
      history: true,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client0x1a0e0002--new",
      network_id: networks(:network1).id,
      history: true,
      deleted_at: DateTime.now,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0003",
      name: "client1",
      network_id: networks(:network1).id,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0004",
      name: "()client0x1a0e0004",
      network_id: networks(:network1).id,
      history: false,
    ).save!

    get(:index, { vipnet_id: "0x1a0e0001" })
    assert_equal(1, assigns["size"])
    assert assigns["search"]

    get(:index, { wrong_search_param: "something" })
    assert_not assigns["search"]

    get(:index, { name: "client0x1a0e0001--old1" })
    assert_equal(2, assigns["size"])

    get(:index, { name: ")client" })
    assert_equal(1, assigns["size"])

    get(:index, { vipnet_id: ".*1a0e" })
    assert_equal(3, assigns["size"])

    get(:index, { vipnet_id: "0x.a.e0001" })
    assert_equal(1, assigns["size"])

    get(:index, { vipnet_id: "0x1a0e00.*", name: "new" })
    assert_equal(1, assigns["size"])

    get(:index, { deleted_at: DateTime.now.strftime("%Y") })
    assert_equal(1, assigns["size"])
    # order
    get(:index, { vipnet_id: "0x1a0e00.*" })
    assert_equal("0x1a0e0004", assigns["nodes"].last.vipnet_id)
    # quick search
    get(:index, { search: "0x1a0e00" })
    assert_equal(3, assigns["size"])
  end

  test "availability" do
    user_session1 = UserSession.create(users(:user1))
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
    )
    node1.save!
    node2.save!
    Iplirconf.destroy_all
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000a",
        },
        "client" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.1",
        },
      },
    ).save!

    get(:availability, { node_id: node1.id })
    assert assigns["response"][:status]
    assert assigns["response"][:parent_id]
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])

    get(:availability, { node_id: "not an id" })
    assert_response :bad_request

    get(:availability, { node_id: node2.id })
    assert_not assigns["response"][:status]
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal("no-accessips", assigns["response"][:fullscreen_tooltip_key])
  end

  test "history" do
    user_session1 = UserSession.create(users(:user1))
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client0x1a0e0001--new",
      network_id: networks(:network1).id,
      history: false,
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client0x1a0e0001--old1_1",
      network_id: networks(:network1).id,
      history: true,
    )
    node3 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client0x1a0e0002--new",
      network_id: networks(:network1).id,
      history: true,
      deleted_at: DateTime.now,
    )
    node4 = Node.new(
      vipnet_id: "0x1a0e0003",
      name: "client1",
      network_id: networks(:network1).id,
      history: false,
    )
    node1.save!
    node2.save!
    node3.save!
    node4.save!

    get(:history, { node_id: node1.id })
    assert assigns["response"][:status]
    assert assigns["response"][:parent_id]
    assert assigns["response"][:row_id]
    assert assigns["response"][:history]
    assert_equal("after", assigns["response"][:place])
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal(1, assigns["response"][:nodes].size)

    get(:history, { node_id: "not an id" })
    assert_response :bad_request

    get(:history, { node_id: node2.id })
    assert assigns["response"][:status]
    assert_equal("before", assigns["response"][:place])
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal(1, assigns["response"][:nodes].size)

    get(:history, { node_id: node3.id })
    assert_not assigns["response"][:status]

    get(:history, { node_id: node4.id })
    assert_not assigns["response"][:status]
  end
end
