require "test_helper"

class Api::V1::BaseControllerTest < ActionController::TestCase
  test "disable api" do
    @controller = Api::V1::AccessipsController.new
    Settings.disable_api = true
    get(:index)
    assert_response(:service_unavailable)
    Settings.disable_api = false
  end
end
