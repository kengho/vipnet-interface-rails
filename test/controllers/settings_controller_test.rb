require "test_helper"

class SettingsControllerTest < ActionController::TestCase
  setup do
    Settings.set_defaults
  end

  test "should be available by administrator role" do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
  end

  test "should be unavailable by user role" do
    UserSession.create(users(:user1))
    get :index
    assert_response :redirect
  end
end
