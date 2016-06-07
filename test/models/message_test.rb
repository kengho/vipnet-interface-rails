require "test_helper"

class MessagesTest < ActiveSupport::TestCase
  test "decode" do
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: false,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
    ).save!
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
    ).save!

    message1 = messages(:meaningless)
    assert_equal("ok", message1.decode)

    message2 = messages(:create_db)
    assert_equal("post nodename.doc", message2.decode)

    message3 = messages(:delete_node)
    nodes_before_deletion = Node.where("vipnet_id = ?", "0x1a0e0001")
    nodes_before_deletion_size = nodes_before_deletion.size
    assert_equal("ok", message3.decode)
    nodes_after_deletion = Node.where("vipnet_id = ?", "0x1a0e0001")
    nodes_after_deletion_size = nodes_after_deletion.size
    # node deletion adds one history node
    assert_equal(1, nodes_after_deletion_size - nodes_before_deletion_size)
    changed_node = nodes_after_deletion.where("history = 'false'").first
    assert changed_node.deleted_at
    assert changed_node.deleted_by_message_id

    message4 = messages(:create_node)
    nodes_before_creation = Node.where("vipnet_id = ?", "0x1a0e0001")
    nodes_before_creation_size = nodes_before_creation.size
    assert_equal("ok", message4.decode)
    nodes_after_creation = Node.where("vipnet_id = ?", "0x1a0e0001")
    nodes_after_creation_size = nodes_after_creation.size
    # node creation adds one history node
    assert_equal(1, nodes_after_creation_size - nodes_before_creation_size)
    changed_node = nodes_after_creation.where("history = 'false'").first
    assert changed_node.created_by_message_id
  end

  test "messages shouldn't change old nodes" do
    node = Node.new(vipnet_id: "0x1a0e0001", name: "client", network_id: networks(:network1).id)
    node.save!
    
    message1 = messages(:delete_node)
    assert_equal("ok", message1.decode)
    node = Node.find_by_id(node.id)
    assert_equal(nil, node.deleted_by_message_id)

    message2 = messages(:delete_node)
    assert_equal("ok", message2.decode)
    node = Node.find_by_id(node.id)
    assert_equal(nil, node.created_by_message_id)
  end

end
