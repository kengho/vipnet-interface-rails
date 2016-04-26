class NodesControllerTest < ActionController::TestCase

  test "available by user role" do
    user_session1 = UserSession.create(users(:user1))
    get :index
    assert_response :success
  end

  test "check params" do
    user_session1 = UserSession.create(users(:user1))

    get :availability, node_id: nodes(:empty_node)
    assert_response :success

    get :availability, node_id: "node dont exist"
    assert_response :bad_request

    get :history, node_id: nodes(:empty_node)
    assert_response :success

    get :history, node_id: "node dont exist"
    assert_response :bad_request
  end

  test "search" do
    user_session1 = UserSession.create(users(:user1))

    get(:index, { vipnet_id: "0x1a0e0601" })
    assert_equal(3, assigns["size_all"])
    assert assigns["search"]

    get(:index, { wrong_search_param: "something" })
    assert_not assigns["search"]

    get(:index, { name: "client0x1a0e0601--old1" })
    assert_equal(2, assigns["size_all"])
    assert_equal(0, assigns["size_no_history"])

    get(:index, { name: ")client" })
    assert_equal(1, assigns["size_all"])

    get(:index, { vipnet_id: ".*0601" })
    assert_equal(3, assigns["size_all"])

    get(:index, { vipnet_id: "0x.a.e0601" })
    assert_equal(3, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e06.*", name: "new" })
    assert_equal(2, assigns["size_all"])

    get(:index, { deleted_at: DateTime.now.strftime("%Y") })
    assert_equal(1, assigns["size_all"])

    # order
    get(:index, { vipnet_id: "0x1a0e06.*" })
    assert_equal("0x1a0e0604", assigns["nodes"].last.vipnet_id)
  end

  test "availability" do
    user_session1 = UserSession.create(users(:user1))

    node1 = nodes(:availability1)
    get(:availability, { node_id: node1.id })
    assert assigns["response"][:status]
    assert assigns["response"][:parent_id]
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])

    get(:availability, { node_id: "not an id" })
    assert_response :bad_request

    node2 = nodes(:availability2)
    get(:availability, { node_id: node2.id })
    assert_not assigns["response"][:status]
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])

    node3 = nodes(:availability3)
    get(:availability, { node_id: node3.id })
    assert_not assigns["response"][:status]
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal("no-accessips", assigns["response"][:fullscreen_tooltip_key])
  end

  test "history" do
    user_session1 = UserSession.create(users(:user1))

    node1 = nodes(:search1)
    get(:history, { node_id: node1.id })
    assert assigns["response"][:status]
    assert assigns["response"][:parent_id]
    assert assigns["response"][:row_id]
    assert assigns["response"][:history]
    assert_equal("after", assigns["response"][:place])
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal(2, assigns["response"][:nodes].size)

    get(:history, { node_id: "not an id" })
    assert_response :bad_request

    node2 = nodes(:search2)
    get(:history, { node_id: node2.id })
    assert assigns["response"][:status]
    assert_equal("before", assigns["response"][:place])
    assert_no_match(/translation missing/, assigns["response"][:tooltip_text])
    assert_equal(1, assigns["response"][:nodes].size)

    node3 = nodes(:search4)
    get(:history, { node_id: node3.id })
    assert_not assigns["response"][:status]

    node4 = nodes(:search5)
    get(:history, { node_id: node4.id })
    assert_not assigns["response"][:status]
  end

  test "vipnet version substitution" do
    user_session1 = UserSession.create(users(:user1))

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "3.1" })
    # version_substitution1 and version_substitution8
    assert_equal(2, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "3.2" })
    assert_equal(3, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "4" })
    assert_equal(3, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "11" })
    assert_equal(1, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "3" })
    assert_equal(5, assigns["size_all"])

    get(:index, { vipnet_id: "0x1a0e08", vipnet_version: "3.0" })
    assert_equal(0, assigns["size_all"])
  end

end
