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

  test "find_or_create_network" do
    network1 = Network.find_or_create_network("6670")
    network2 = Network.find_or_create_network("6671")
    assert_equal("existing_network", network1.name)
    assert network1
  end
end
