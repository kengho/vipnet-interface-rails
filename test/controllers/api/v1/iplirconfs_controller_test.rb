require "test_helper"

class Api::V1::IplirconfsControllerTest < ActionController::TestCase
  setup do
    request.env["HTTP_AUTHORIZATION"] = "Token token=\"POST_HW_TOKEN\""
  end

  test "correct token should be provided" do
    request.env["HTTP_AUTHORIZATION"] = "incorrect token"
    post(:create)
    assert_response :unauthorized
  end

  test "file should be provided" do
    post(:create, params: { coord_vid: "0x1a0e000a" })
    assert_equal("error", @response.body)
  end

  test "coord_vid should be provided" do
    iplirconf_empty = fixture_file_upload(
      "iplirconfs/empty.conf",
      "application/octet-stream",
    )
    post(:create, params: { file: iplirconf_empty })
    assert_equal("error", @response.body)
  end
end
