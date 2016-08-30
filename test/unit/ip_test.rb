require "test_helper"

class IPTest < ActionController::TestCase
  test "should be able to figure out whether string is IPv4 or not" do
    assert IP::ip?("192.168.0.1")
    assert IP::ip?("255.255.255.255")
    assert_not IP::ip?("not ip")
    assert_not IP::ip?("256.168.0.1")
    assert_not IP::ip?("asd.1.1.1")
    assert_not IP::ip?("192.168.0.1/32")
  end

  test "should be able to figure out whether string is CIDR or not" do
    assert IP::cidr("192.168.0.1/24")
    assert IP::cidr("255.255.255.255/32")
    assert_not IP::cidr("not cidr")
    assert_not IP::cidr("192.168.0.1/33")
  end

  test "should convert IPv4 to u32" do
    assert_equal(3232235521, IP::u32("192.168.0.1"))
    assert_equal(4294967295, IP::u32("255.255.255.255"))
    assert_not IP::u32("256.256.256.256")
  end

  test "should convert u32 to IPv4" do
    assert_equal("192.168.0.1", IP::ip(3232235521))
    assert_equal("255.255.255.255", IP::ip(4294967295))
    assert_not IP::ip(4294967296)
  end

  test "should be able to figure out whether string is IPv4 range or not" do
    assert IP::range("192.168.0.1-192.168.0.2")
    assert IP::range("0.0.0.0-255.255.255.255")
    assert_not IP::range("not range")
    assert_not IP::range("192.168.0.2-192.168.0.1")
  end

  test "should calculate bounds by cidr or range" do
    assert_equal([3232235520, 3232235775], IP::u32_bounds("192.168.0.0/24"))
    assert_equal([3232235520, 3232235775], IP::u32_bounds("192.168.0.100/24"))
    assert_equal([3232235521, 3232235521], IP::u32_bounds("192.168.0.1/32"))
    assert_equal([3232235521, 3232235522], IP::u32_bounds("192.168.0.1-192.168.0.2"))
    assert_equal([0, 4294967295], IP::u32_bounds("0.0.0.0-255.255.255.255"))
    assert_not IP::u32_bounds("192.168.0.1/33")
    assert_not IP::u32_bounds("192.168.0.2-192.168.0.1")
  end
end
