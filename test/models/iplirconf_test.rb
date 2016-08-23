require "test_helper"

class IplirconfsTest < ActiveSupport::TestCase
  setup do
    @coordinator1 = coordinators(:coordinator1)
  end

  test "shouldn't save without coordinator" do
    iplirconf = Iplirconf.new()
    assert_not iplirconf.save
  end

  test "when coordinator destroys, all its iplirconf destroys" do
    Iplirconf.push(hash: {}, belongs_to: @coordinator1)
    assert_equal(1, Iplirconf.all.size)
    @coordinator1.destroy
    assert_equal(0, Iplirconf.all.size)
  end
end
