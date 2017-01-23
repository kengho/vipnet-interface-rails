require "test_helper"

class IPv4Test < ActionController::TestCase
  test "should be able to figure out whether string is IPv4 or not" do
    assert IPv4.ip?("192.168.0.1")
    assert IPv4.ip?("255.255.255.255")
    assert_not IPv4.ip?("not ip")
    assert_not IPv4.ip?("256.168.0.1")
    assert_not IPv4.ip?("asd.1.1.1")
    assert_not IPv4.ip?("192.168.0.1/32")
  end

  test "should be able to figure out whether string is CIDR or not" do
    assert IPv4.cidr("192.168.0.1/24")
    assert IPv4.cidr("255.255.255.255/32")
    assert_not IPv4.cidr("not cidr")
    assert_not IPv4.cidr("192.168.0.1/33")
  end

  test "should convert IPv4 to u32" do
    assert_equal(3_232_235_521, IPv4.u32("192.168.0.1"))
    assert_equal(4_294_967_295, IPv4.u32("255.255.255.255"))
    assert_not IPv4.u32("256.256.256.256")
  end

  test "should convert u32 to IPv4" do
    assert_equal("192.168.0.1", IPv4.ip(3_232_235_521))
    assert_equal("255.255.255.255", IPv4.ip(4_294_967_295))
    assert_not IPv4.ip(4_294_967_296)
  end

  test "should be able to figure out whether string is IPv4 range or not" do
    assert IPv4.range("192.168.0.1-192.168.0.2")
    assert IPv4.range("0.0.0.0-255.255.255.255")
    assert_not IPv4.range("not range")
    assert_not IPv4.range("192.168.0.2-192.168.0.1")
  end

  test "should calculate bounds by cidr or range" do
    assert_equal([3_232_235_520, 3_232_235_775], IPv4.u32_bounds("192.168.0.0/24"))
    assert_equal([3_232_235_520, 3_232_235_775], IPv4.u32_bounds("192.168.0.100/24"))
    assert_equal([3_232_235_521, 3_232_235_521], IPv4.u32_bounds("192.168.0.1/32"))
    assert_equal([3_232_235_521, 3_232_235_522], IPv4.u32_bounds("192.168.0.1-192.168.0.2"))
    assert_equal([0, 4_294_967_295], IPv4.u32_bounds("0.0.0.0-255.255.255.255"))
    assert_not IPv4.u32_bounds("192.168.0.1/33")
    assert_not IPv4.u32_bounds("192.168.0.2-192.168.0.1")
  end
end
