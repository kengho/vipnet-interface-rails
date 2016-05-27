class NodesControllerIndexTest < ActionController::TestCase

  def setup
    @controller = NodesController.new
  end

  test "vipnet version substitution" do
    user_session1 = UserSession.create(users(:user1))
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client1",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "3.0-670" }
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client2",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "3.2-672" }
    )
    node3 = Node.new(
      vipnet_id: "0x1a0e0003",
      name: "client3",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "0.3-2" }
    )
    node4 = Node.new(
      vipnet_id: "0x1a0e0004",
      name: "client4",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "4.20-0" }
    )
    node5 = Node.new(
      vipnet_id: "0x1a0e0005",
      name: "client5",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "4.20-1" }
    )
    node6 = Node.new(
      vipnet_id: "0x1a0e0006",
      name: "client6",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "3.2-673" }
    )
    node7 = Node.new(
      vipnet_id: "0x1a0e0007",
      name: "client7",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "" }
    )
    node8 = Node.new(
      vipnet_id: "0x1a0e0008",
      name: "client8",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "3.0-671" }
    )
    node9 = Node.new(
      vipnet_id: "0x1a0e0009",
      name: "client9",
      network_id: networks(:network1).id,
      vipnet_version: { "summary" => "4.30-0" }
    )
    node1.save!
    node2.save!
    node3.save!
    node4.save!
    node5.save!
    node6.save!
    node7.save!
    node8.save!
    node9.save!

    get(:index, { vipnet_id: "0x1a0e" })
    assert_equal("3.1", css_select("#node-#{node1.id}__vipnet-version").children.text)
    assert_equal("3.2", css_select("#node-#{node2.id}__vipnet-version").children.text)
    assert_equal("3.2 (11.19855)", css_select("#node-#{node3.id}__vipnet-version").children.text)
    assert_equal("4", css_select("#node-#{node4.id}__vipnet-version").children.text)
    assert_equal("4", css_select("#node-#{node5.id}__vipnet-version").children.text)
    assert_equal("3.2", css_select("#node-#{node6.id}__vipnet-version").children.text)
    assert_equal("", css_select("#node-#{node7.id}__vipnet-version").children.text)
    assert_equal("3.1", css_select("#node-#{node8.id}__vipnet-version").children.text)
    assert_equal("4", css_select("#node-#{node9.id}__vipnet-version").children.text)
  end

end
