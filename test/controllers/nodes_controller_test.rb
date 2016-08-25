class NodesControllerTest < ActionController::TestCase
  test "should be available by user role" do
    user_session1 = UserSession.create(users(:user1))
    get :index
    assert_response :success
  end
end
