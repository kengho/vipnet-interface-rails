class NodesControllerTest < ActionController::TestCase

  test "available by user role" do
    user_session1 = UserSession.create(users(:user1))

    get :index
    assert_response :success

    get :availability, node_id: nodes(:empty_node)
    assert_response :success

    get :availability, node_id: "node dont exist"
    assert_response :bad_request
    
    get :history, node_id: nodes(:empty_node)
    assert_response :success

    get :history, node_id: "node dont exist"
    assert_response :bad_request
  end

end
