require "test_helper"

class AccessIpTest < ActiveSupport::TestCase
  test "shouldn't save second accessip for same node and same coordinator" do
    node = CurrentNode.new(vid: "0x1a0e0001", network: networks(:network1))
    node.save!
    accessip1 = AccessIp.new(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert accessip1.save
    accessip2 = AccessIp.new(u32: 0, node: node, coordinator: coordinators(:coordinator1))
    assert_not accessip2.save
  end
end
