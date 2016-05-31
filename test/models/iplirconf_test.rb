require "test_helper"

class IplirconfsTest < ActiveSupport::TestCase
  test "validations" do
    coordinator = coordinators(:coordinator1)
    iplirconf1 = Iplirconf.new(coordinator_id: nil)
    iplirconf2 = Iplirconf.new(coordinator_id: coordinator.id)
    iplirconf3 = Iplirconf.new(coordinator_id: coordinator.id)
    assert_not iplirconf1.save
    assert iplirconf2.save
    assert_not iplirconf3.save
  end

  test "changed_sections" do
    iplirconf1 = Iplirconf.new(coordinator_id: coordinators(:coordinator1).id)
    iplirconf1.save!
    initial_sections = {
      "0x1a0e000a" => {
        :id => "0x1a0e000a",
        :name => "coordinator1",
        :filterdefault => "pass",
        :ip => ["192.0.2.1", "192.0.2.3"].to_s,
        :tunnel => "192.0.2.100-192.0.2.200 to 192.0.2.100-192.0.2.200",
        :firewallip => "192.0.2.4",
        :port => "55777",
        :proxyid => "0x00000000",
        :usefirewall => "off",
        :fixfirewall => "off",
        :virtualip => "198.51.100.1",
        :version => "3.0-670",
      },
      "0xffffffff" => {
        :name => "Encrypted broadcasts",
        :filterdefault => "drop",
        :filterudp => [
          "137, 137, pass, any",
          "138, 138, pass, any",
          "68, 67, pass, any",
          "67, 68, pass, any",
          "2046, 0-65535, pass, recv",
          "2046, 2046, pass, send",
          "2048, 0-65535, pass, recv",
          "2050, 0-65535, pass, recv",
          "2050, 2050, pass, send",
        ],
      },
      "0xfffffffe" => {
        :id => "0xfffffffe",
        :name => "Main Filter",
        :filterdefault => "pass",
      },
      "0x1a0e000b" => {
        :id => "0x1a0e000b",
        :name => "administrator",
        :filterdefault => "pass",
        :ip => ["192.0.2.5"].to_s,
        :accessip => "198.51.100.2",
        :firewallip => "192.0.2.6",
        :port => "55777",
        :proxyid => "0xfffffffe",
        :dynamic_timeout => "0",
        :usefirewall => "on",
        :virtualip => "198.51.100.2",
        :version => "3.2-672",
      },
      "0x1a0e000c" => {
        :id => "0x1a0e000c",
        :name => "client1",
        :filterdefault => "pass",
        :ip => ["192.0.2.7"].to_s,
        :accessip => "198.51.100.3",
        :firewallip => "192.0.2.8",
        :port => "55777",
        :proxyid => "0xfffffffe",
        :dynamic_timeout => "0",
        :usefirewall => "on",
        :virtualip => "198.51.100.3",
        :version => "0.3-2",
      },
    }
    iplirconf2 = Iplirconf.new(coordinator_id: coordinators(:coordinator1).id)
    iplirconf2.sections = initial_sections

    assert_equal(initial_sections, iplirconf1.changed_sections(iplirconf2))

    iplirconf1.sections = initial_sections
    iplirconf1.save!
    changed_sections1 = initial_sections
    changed_sections1["0x1a0e000a"][:ip] = ["192.0.2.4", "192.0.2.5"].to_s
    changed_sections1["0x1a0e000a"][:name] = "coordinator1_changed"
    changed_sections1["0x1a0e000c"][:version] = "0.3-3"
    changed_sections1["0x1a0e000c"][:accessip] = "192.0.2.7"
    iplirconf2.sections = changed_sections1

    assert_equal({
      "0x1a0e000a" => {
        :ip => ["192.0.2.4", "192.0.2.5"].to_s,
        :name => "coordinator1_changed",
      },
      "0x1a0e000c" => {
        :version => "0.3-3",
        :accessip => "192.0.2.7",
      },
    }, iplirconf1.changed_sections(iplirconf2))

    iplirconf1.sections = changed_sections1
    iplirconf1.save!
    changed_sections2 = changed_sections1
    changed_sections2["0x1a0e000a"][:ip] = ["192.0.2.4", "192.0.2.6"].to_s
    iplirconf2.sections = changed_sections2

    assert_equal({
      "0x1a0e000a" => {
        :ip => ["192.0.2.4", "192.0.2.6"].to_s,
      },
    }, iplirconf1.changed_sections(iplirconf2))
  end
end
