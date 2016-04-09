require "test_helper"

class CoordinatorsTest < ActiveSupport::TestCase

  test "validations" do
    network = Network.new
    network.save(:validate => false)
    coordinator1 = Coordinator.new(vipnet_id: nil, network_id: network.id)
    coordinator2 = Coordinator.new(vipnet_id: "0x1a0e000a", network_id: nil)
    coordinator3 = Coordinator.new(vipnet_id: "0x1a0e000b", network_id: network.id)
    coordinator4 = Coordinator.new(vipnet_id: "0x1a0e000b", network_id: network.id)
    coordinator5 = Coordinator.new(vipnet_id: "1A0E000A", network_id: network.id)
    assert_not coordinator1.save
    assert_not coordinator2.save
    coordinator3.save
    assert_not coordinator4.save
    assert_not coordinator5.save
  end

end
