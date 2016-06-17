require "test_helper"

class NodesTest < ActiveSupport::TestCase
  test "validations" do
    network = networks(:network1)
    node1 = Node.new(vipnet_id: nil, network_id: network.id, name: "name")
    node2 = Node.new(vipnet_id: "0x1a0e0100", network_id: nil, name: "name")
    node3 = Node.new(vipnet_id: "0x1a0e0100", network_id: network.id, name: nil)
    node4 = Node.new(vipnet_id: "1A0E0100", network_id: network.id, name: "name")
    assert_not node1.save
    assert_not node2.save
    assert_not node3.save
    assert_not node4.save
  end

  test "accessips" do
    node1 = Node.new(
      vipnet_id: "0xffffffff",
      name: "test",
      network_id: networks(:network1).id,
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
    )
    node1.save!
    node2.save!
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "0x1a0e0001" => {
          :accessip => "192.0.2.1",
        },
      },
    ).save!
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator2).id,
      sections: {
        "0x1a0e0001" => {
          :accessip => "192.0.2.2",
        },
      },
    ).save!

    assert_equal([], node1.accessips)
    assert_equal(["192.0.2.1", "192.0.2.2"].sort, node2.accessips)
    assert_equal({ "0x1a0e000a" => "192.0.2.1", "0x1a0e000b" => "192.0.2.2" }, node2.accessips(Hash))
  end

  test "availability" do
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
    )
    node1.save!
    node2.save!
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "0x1a0e0001" => {
          :accessip => "192.0.2.1",
        },
      },
    ).save!

    assert_equal({ :data => { :availability => true }}, node1.availability)
    assert_equal({ :errors => [{ :title => "internal", :detail => "no-accessips" }]}, node2.availability)
  end

  test "ip_summary" do
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      ip: {
        "0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.2\"]",
        "0x1a0e000b" => "[\"192.0.2.3\", \"192.0.2.4\"]",
      }
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      ip: {}
    )
    node1.save!
    node2.save!

    assert_equal("192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4", node1.ip_summary)
    assert_equal("", node2.ip_summary)
  end

  test "version_summary" do
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      version: {
        "0x1a0e000a" => "1.1",
        "0x1a0e000b" => "1.1",
      },
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      version: {
        "0x1a0e000a" => "1.1",
        "0x1a0e000b" => "1.2",
      },
    )
    node3 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      version: {},
    )
    node1.save!
    node2.save!
    node3.save!

    assert_equal("1.1", node1.version_summary)
    assert_equal("?", node2.version_summary)
    assert_equal("", node3.version_summary)
  end

  test "mftp_server" do
    server1 = Node.new(
      vipnet_id: "0x1a0f000a",
      name: "server1",
      network_id: networks(:network1).id,
      abonent_number: "0000",
      server_number: "0001",
      category: "server",
    )
    server2 = Node.new(
      vipnet_id: "0x1a0f000b",
      name: "server2",
      network_id: networks(:network1).id,
      abonent_number: "0000",
      server_number: "0002",
      category: "server",
    )
    client1 = Node.new(
      vipnet_id: "0x1a0f0001",
      name: "client1",
      network_id: networks(:network1).id,
      abonent_number: "0001",
      server_number: "0001",
      category: "client",
    )
    client2 = Node.new(
      vipnet_id: "0x1a0f0003",
      name: "client3",
      network_id: networks(:network1).id,
      abonent_number: "0002",
    )
    server1.save!
    server2.save!
    client1.save!
    client2.save!

    assert_equal(server1, client1.mftp_server)
    assert_equal(nil, client2.mftp_server)
    assert_equal(false, server1.mftp_server)
  end

  test "clean" do
    # history, enabled, ip, version, tickets have defaults
    # 0x1a0e0001
    Node.new( # 1
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 2
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
      ip: { "summary" => "", "0x1a0e000a" => "[]" },
      version: { "summary" => "", "0x1a0e000a" => nil },
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 3
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    node14 = Node.new( # 4
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    )
    node14.save!
    Node.new( # 5
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 6
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 7
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    # 0x1a0e0002 #1
    Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 8
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    Node.new( # 9
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    node110 = Node.new( # 10
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    )
    node110.save!
    node111 = Node.new( # 11
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      version: { "summary" => "4"},
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    )
    node111.save!
    node112 = Node.new( # 12
      vipnet_id: "0x1a0e0001",
      name: "client-renamed",
      network_id: networks(:network1).id,
      history: true,
      version: { "summary" => "4"},
      deleted_at: DateTime.now,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    )
    node112.save!
    # 0x1a0e0002 #2
    node22 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    )
    node22.save!
    Settings.networks_to_ignore = "6671,1234"
    Node.new(
      vipnet_id: "0x1a0f0003",
      name: "client",
      network_id: networks(:network2).id,
      category: "client",
      abonent_number: "0001",
      server_number: "0001",
    ).save!
    # after cleaning
    # 0x1a0e0001 should be only 12 (112), 11 (111), 10 (110), 4 (14) (overall 4)
    # 0x1a0e0002 should be only 2 (22) (overall 1)
    # 0x1a0f0003 should disappear
    assert_equal(12 + 2 + 1, Node.all.size)
    Node.clean
    assert_equal(4 + 1, Node.all.size)
    assert Node.find_by_id(node112.id)
    assert Node.find_by_id(node111.id)
    assert Node.find_by_id(node110.id)
    assert Node.find_by_id(node14.id)
    assert Node.find_by_id(node22.id)
  end
end
