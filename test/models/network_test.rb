require "test_helper"

class NetworksTest < ActiveSupport::TestCase
  setup do
    Network.destroy_all
  end

  test "shouldn't save without network_vid" do
    network = Network.new()
    assert_not network.save
  end

  test "shouldn't save two networks with same network_vid" do
    Network.create!(network_vid: "6670")
    network = Network.new(network_vid: "6670")
    assert_not network.save
  end

  test "shouldn't save network with wrong network_vid" do
    network = Network.new(network_vid: "0x1a0e0001")
    assert_not network.save
  end

  test "should save network with network_vid in range 0x1-0xffff" do
    network1 = Network.new(network_vid: "0xffff".to_i(16).to_s)
    network2 = Network.new(network_vid: "1")
    assert network1.save
    assert network2.save
  end
end
