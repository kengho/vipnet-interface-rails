require "test_helper"

class IplirconfsTest < ActiveSupport::TestCase

  test "validations" do
    coordinator = coordinators(:coordinator1)
    iplirconf1 = Iplirconf.new(coordinator_id: nil)
    iplirconf2 = Iplirconf.new(coordinator_id: coordinator.id)
    assert_not iplirconf1.save
    assert iplirconf2.save
  end

  test "parse" do
    iplirconf1 =iplirconfs(:iplirconf_parse1)
    assert iplirconf1.parse
    assert iplirconf1.sections["self"]
    assert_equal("0x1a0e030a", iplirconf1.sections["self"]["vipnet_id"])
    # 3 sections: "self", "0x1a0e030a" and "0x1a0e0301"
    assert_equal(3, iplirconf1.sections.size)

    iplirconf1.sections.each do |_, section|
      assert_instance_of(Hash, section)
      case section["vipnet_id"]
      when "0x1a0e030a"
        assert_equal("coordinator", section["name"])
        assert_equal(["192.0.2.1", "192.0.2.2", "192.0.2.3"], section["ips"])
        assert_equal("192.0.2.2", section["accessip"])
        assert_equal("3.0-670", section["vipnet_version"])
      when "0x1a0e0301"
        assert_equal("client1", section["name"])
        assert_equal(["192.0.2.11"], section["ips"])
        assert_equal("192.0.2.12", section["accessip"])
        assert_equal("3.2-672", section["vipnet_version"])
      end
    end

    iplirconf2 =iplirconfs(:iplirconf_parse2)
    assert_not iplirconf2.parse
  end

end
