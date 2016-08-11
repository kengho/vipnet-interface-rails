require "test_helper"

class GarlsndsTest < ActiveSupport::TestCase
  setup do
    class Storage < Garland
    end
  end

  test "validations" do
    s1 = Storage.new(entity: "{}", entity_type: nil)
    s2 = Storage.new(entity: nil, entity_type: Garland::SNAPSHOT)
    s3 = Storage.new(entity: "{}", entity_type: Garland::DIFF)
    assert_not s1.save
    assert_not s2.save
    assert s3.save
  end
end
