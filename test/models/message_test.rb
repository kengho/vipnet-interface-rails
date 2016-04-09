require "test_helper"

class MessagesTest < ActiveSupport::TestCase

  test "decode" do
    message1 = messages(:meaningless)
    assert_equal("ok", message1.decode)

    message2 = messages(:create_db)
    assert_equal("post nodename.doc", message2.decode)

    message3 = messages(:delete_node)
    nodes_before_deletion = Node.where("vipnet_id = ?", "0x1a0e0400")
    nodes_before_deletion_size = nodes_before_deletion.size
    assert_equal("ok", message3.decode)
    nodes_after_deletion = Node.where("vipnet_id = ?", "0x1a0e0400")
    nodes_after_deletion_size = nodes_after_deletion.size
    # node deletion adds one history node
    assert_equal(1, nodes_after_deletion_size - nodes_before_deletion_size)
    nodes_after_deletion.each do |node_after_deletion|
      assert node_after_deletion.deleted_at
    end

    message4 = messages(:create_node)
    assert_equal("ok", message4.decode)
    assert nodes(:message_decode4).created_by_message_id
  end

end
