class NodesControllerIndexTest < ActionController::TestCase

  def setup
    @controller = NodesController.new
  end

  test "vipnet version substitution" do
    user_session1 = UserSession.create(users(:user1))

    id1 = nodes(:version_substitution1).id
    id2 = nodes(:version_substitution2).id
    id3 = nodes(:version_substitution3).id
    id4 = nodes(:version_substitution4).id
    id5 = nodes(:version_substitution5).id
    id6 = nodes(:version_substitution6).id
    id7 = nodes(:version_substitution7).id
    get(:index, { vipnet_id: "0x1a0e08" })
    assert_equal("3.1", css_select("#node-#{id1}__vipnet-version").children.text)
    assert_equal("3.2", css_select("#node-#{id2}__vipnet-version").children.text)
    assert_equal("3.2 (11.19855)", css_select("#node-#{id3}__vipnet-version").children.text)
    assert_equal("4.2", css_select("#node-#{id4}__vipnet-version").children.text)
    assert_equal("4.2", css_select("#node-#{id5}__vipnet-version").children.text)
    assert_equal("3.2", css_select("#node-#{id6}__vipnet-version").children.text)
    assert_equal("", css_select("#node-#{id7}__vipnet-version").children.text)
  end

end
