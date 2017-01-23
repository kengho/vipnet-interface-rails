require "test_helper"

class NodenamesTest < ActiveSupport::TestCase
  setup do
    @network1 = networks(:network1)
  end

  test "shouldn't save without network" do
    nodename = Nodename.new
    assert_not nodename.save
  end

  test "when network destroys, all its nodenames destroys" do
    Nodename.push(hash: {}, belongs_to: @network1)
    assert_equal(3, Nodename.all.size)
    @network1.destroy
    assert_equal(0, Nodename.all.size)
  end
end
