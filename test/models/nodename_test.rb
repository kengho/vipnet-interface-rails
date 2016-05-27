require "test_helper"

class NodenamesTest < ActiveSupport::TestCase
  test "validations" do
    nodename1 = Nodename.new(network_id: nil)
    assert_not nodename1.save
  end
end
