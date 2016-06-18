require "test_helper"

class NetworksTest < ActiveSupport::TestCase
  test "validations" do
    network1 = Network.new(vipnet_network_id: nil)
    network2 = Network.new(vipnet_network_id: "6671")
    network2.save
    network3 = Network.new(vipnet_network_id: "6671")
    network4 = Network.new(vipnet_network_id: "network")
    assert_not network1.save
    assert_not network3.save
    assert_not network4.save
  end
end
