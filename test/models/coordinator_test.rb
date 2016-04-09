require "test_helper"

class CoordinatorsTest < ActiveSupport::TestCase

  test "presence" do
    network = Network.new
    network.save(:validate => false)
    coordinator1 = Coordinator.new(vipnet_id: nil, network_id: network.id)
    coordinator2 = Coordinator.new(vipnet_id: "vipnet_id", network_id: nil)
    coordinator3 = Coordinator.new(vipnet_id: "same_vipnet_id", network_id: network.id)
    coordinator4 = Coordinator.new(vipnet_id: "same_vipnet_id", network_id: network.id)
    assert_not coordinator1.save
    assert_not coordinator2.save
    coordinator3.save
    assert_not coordinator4.save
  end

end
