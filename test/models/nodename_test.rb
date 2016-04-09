require "test_helper"

class NodenamesTest < ActiveSupport::TestCase

  test "validations" do
    nodename1 = Nodename.new(network_id: nil)
    assert_not nodename1.save
  end

  test "read_content" do
    content1 =
    "administrator                                      1 A 00001A0E00010001 1A0E0501\r\n" \
    "client                                             1 A 00001A0F00010002 1A0F0502\r\n" \
    "coordinator1                                       1 S 00001A0E00010000 1A0E050A\r\n" \
    "coordinator2                                       0 S 00001A0E00020000 1A0E050D\r\n" \
    "group1                                             1 G 00001A0E00020000 1A0E050E\r\n" \
    "group2                                             1 G 00001A0E00020000 1A0E050F\r\n" \
    ""
    nodename1 = Nodename.new
    response1 = nodename1.read_content(content1, networks(:network1).id)
    assert response1

    # 2 coordinators + 2 clients, ignoring groups
    assert_equal(4, nodename1.content.size)

    nodename1.content.each do |_, record|
      assert_match(/0x[0-9a-f]{8}/, record["vipnet_id"])
      case record["vipnet_id"]
      when "0x1a0e0501"
        assert_equal("administrator", record["name"])
        assert_equal("6670", record["vipnet_network_id"])
        assert_equal("client", record["category"])
        assert_equal(true, record["enabled"])
        assert_equal("0001", record["server_number"])
        assert_equal("0001", record["abonent_number"])
      when "0x1a0f0502"
        assert_equal("6671", record["vipnet_network_id"])
        assert_equal("0002", record["abonent_number"])
      when "0x1a0e050a"
        assert_equal("server", record["category"])
      when "0x1a0e050d"
        assert_equal(false, record["enabled"])
      end
    end

    content2 = ""
    nodename2 = Nodename.new
    response2 = nodename1.read_content(content2, networks(:network1).id)
    assert_not response2
  end

end
