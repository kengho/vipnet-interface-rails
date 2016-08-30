class NodesControllerTest < ActionController::TestCase
  setup do
    @session = UserSession.create(users(:user1))
    @network = networks(:network1)
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
end
