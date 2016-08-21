require "test_helper"

class NodenamesTest < ActiveSupport::TestCase
  test "should not save without network" do
    n = Nodename.new(entity: "{}", entity_type: Garland::SNAPSHOT)
    assert_not n.save
  end

  test "should not save if belongs_to_type isn't 'Network'" do
    @network1 = networks(:network1)
    Nodename.push(hash: "{}", belongs_to: @network1)
    n = Nodename.first
    n.belongs_to_type = "Something"
    assert_not n.save
  end
end
