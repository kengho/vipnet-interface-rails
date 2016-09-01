require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  test "should be able to disable api" do
    Settings.disable_api = true
    get api_v1_accessips_url
    assert_response(:service_unavailable)
    Settings.disable_api = false
  end
end
