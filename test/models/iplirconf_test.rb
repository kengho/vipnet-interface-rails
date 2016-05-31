require "test_helper"

class IplirconfsTest < ActiveSupport::TestCase
  test "validations" do
    coordinator = coordinators(:coordinator1)
    iplirconf1 = Iplirconf.new(coordinator_id: nil, sections: { "self": {} })
    iplirconf2 = Iplirconf.new(coordinator_id: coordinator.id, sections: nil)
    iplirconf3 = Iplirconf.new(coordinator_id: coordinator.id, sections: { "self": {} })
    iplirconf4 = Iplirconf.new(coordinator_id: coordinator.id, sections: { "self": {} })
    assert_not iplirconf1.save
    assert_not iplirconf2.save
    assert iplirconf3.save
    assert_not iplirconf4.save
  end
end
