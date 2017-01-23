require "test_helper"

class CoordinatorsTest < ActiveSupport::TestCase
  setup do
    @network1 = networks(:network1)
    @network2 = networks(:network2)
  end

  test "shouldn't save without network" do
    coordinator = Coordinator.new(vid: "0x1a0e0001")
    assert_not coordinator.save
  end

  test "shouldn't save without vid" do
    coordinator = Coordinator.new(network: @network1)
    assert_not coordinator.save
  end

  test "shouldn't save two coordinators with same vids" do
    Coordinator.create!(vid: "0x1a0e0001", network: @network1)
    coordinator = Coordinator.new(vid: "0x1a0e0001", network: @network1)
    assert_not coordinator.save
  end

  test "shouldn't save with wrong vid" do
    coordinator = Coordinator.new(vid: "1A0E000A", network: @network1)
    assert_not coordinator.save
  end
end
