class NetworksControllerTest < ActionController::TestCase
  test "should be available by administrator role" do
    user_session1 = UserSession.create(users(:administrator))
    get :index
    assert_response :success
  end

  test "should be unavailable by user role" do
    user_session1 = UserSession.create(users(:user1))
    get :index
    assert_response :redirect
  end
end
