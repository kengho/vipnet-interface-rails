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

  test "normalize_vipnet_id" do
    vipnet_id1 = Node.normalize_vipnet_id("1A0E0100")
    vipnet_id2 = Node.normalize_vipnet_id("not looks like id at all")
    assert_equal("0x1a0e0100", vipnet_id1)
    assert_equal(false, vipnet_id2)
  end

  test "network" do
    network1 = Node.network("0x1a0e0100")
    network2 = Node.network("not looks like id at all")
    assert_equal("6670", network1)
    assert_equal(false, network2)
  end

  test "accessips" do
    Node.destroy_all
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
    Iplirconf.destroy_all
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000a",
        },
        "client" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.1",
        },
      },
    ).save!
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator2).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000b",
        },
        "client" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.2",
        },
      },
    ).save!

    assert_equal([], node1.accessips)
    assert_equal(["192.0.2.1", "192.0.2.2"], node2.accessips)
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
    Iplirconf.destroy_all
    Iplirconf.new(
      coordinator_id: coordinators(:coordinator1).id,
      sections: {
        "self" => {
          "vipnet_id" => "0x1a0e000a",
        },
        "client" => {
          "vipnet_id" => "0x1a0e0001",
          "accessip" => "192.0.2.1",
        },
      },
    ).save!

    assert_equal({ :data => { :availability => true }}, node1.availability)
    assert_equal({ :errors => [{ :title => "internal", :detail => "no-accessips" }]}, node2.availability)
  end

  test "ips_summary" do
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      ips: {
        "0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.2\"]",
        "0x1a0e000b" => "[\"192.0.2.3\", \"192.0.2.4\"]",
      }
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      ips: {}
    )
    node1.save!
    node2.save!

    assert_equal("192.0.2.1, 192.0.2.2, 192.0.2.3, 192.0.2.4", node1.ips_summary)
    assert_equal("", node2.ips_summary)
  end

  test "vipnet_versions_summary" do
    Node.destroy_all
    node1 = Node.new(
      vipnet_id: "0x1a0e0001",
      name: "client",
      network_id: networks(:network1).id,
      vipnet_version: {
        "0x1a0e000a" => "1.1",
        "0x1a0e000b" => "1.1",
      },
    )
    node2 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      vipnet_version: {
        "0x1a0e000a" => "1.1",
        "0x1a0e000b" => "1.2",
      },
    )
    node3 = Node.new(
      vipnet_id: "0x1a0e0002",
      name: "client",
      network_id: networks(:network1).id,
      vipnet_version: {},
    )
    node1.save!
    node2.save!
    node3.save!

    assert_equal("1.1", node1.vipnet_version_summary)
    assert_equal("?", node2.vipnet_version_summary)
    assert_equal("", node3.vipnet_version_summary)
  end

  test "mftp_server" do
    Node.destroy_all
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
end
