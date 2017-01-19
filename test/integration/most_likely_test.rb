require "test_helper"

class MostLikelyTest < ActionDispatch::IntegrationTest
  setup do
    @network1 = networks(:network1)
    @network2 = networks(:network2)
    @coordinator1 = coordinators(:coordinator1)
    @coordinator2 = coordinators(:coordinator2)
    @coordinator3 = coordinators(:coordinator3)
    @coordinator4 = coordinators(:coordinator4)

    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e000a",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e000b",
      category: "server",
      abonent_number: "0000",
      server_number: "0002",
    )
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f000a",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f000b",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
  end

  test "should calculate most likely version out of all" do
    ncc_node = CurrentNccNode.new(network: @network1, vid: "0x1a0e0001"); ncc_node.save!
    CurrentHwNode.create!(coordinator: @coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: @coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator4, ncc_node: ncc_node, version: "4")
    assert_equal("4", ncc_node.most_likely(:version))
  end

  test "should calculate most likely version out of all (mftp server)" do
    ncc_node = CurrentNccNode.new(
      network: @network1,
      vid: "0x1a0e0001",
      category: "client",
      server_number: "0002",
    ); ncc_node.save!

    # 0x1a0e000a: 2 clients registered
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0002",
      category: "client",
      server_number: "0001",
    ); ncc_node.save!
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0003",
      category: "client",
      server_number: "0001",
    )

    CurrentHwNode.create!(coordinator: @coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: @coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator4, ncc_node: ncc_node, version: "4")

    # "coordinator2" is ncc_node's mftp server, therefore here comes "3".
    assert_equal("3", ncc_node.most_likely(:version))
  end

  test "should calculate most likely version out of all (weights)" do
    ncc_node = CurrentNccNode.new(network: @network1, vid: "0x1a0e0001"); ncc_node.save!

    # 0x1a0e000a: 2 clients registered
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0002",
      category: "client",
      server_number: "0001",
    ); ncc_node.save!
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0003",
      category: "client",
      server_number: "0001",
    )

    # 0x1a0e000b: 3 clients registered
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0004",
      category: "client",
      server_number: "0002",
    )
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0005",
      category: "client",
      server_number: "0002",
    )
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0006",
      category: "client",
      server_number: "0002",
    )

    # 0x1a0f000a: 1 client registered
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f0001",
      category: "client",
      server_number: "0001",
    )

    # 0x1a0f000b: 1 client registered
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f0002",
      category: "client",
      server_number: "0002",
    )

    CurrentHwNode.create!(coordinator: @coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: @coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator4, ncc_node: ncc_node, version: "4")

    # We trust the most in coordinator2's data because it have more clients registered.
    assert_equal("3", ncc_node.most_likely(:version))
  end

  test "should calculate most likely version out of all (lowest vid)" do
    ncc_node = CurrentNccNode.new(network: @network1, vid: "0x1a0e0001"); ncc_node.save!

    # 0x1a0e000a: 1 client registered
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0002",
      category: "client",
      server_number: "0001",
    )

    # 0x1a0e000b: 1 client registered
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e0003",
      category: "client",
      server_number: "0002",
    )

    # 0x1a0f000a: 1 client registered
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f0001",
      category: "client",
      server_number: "0001",
    )

    # 0x1a0f000b: 1 client registered
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f0002",
      category: "client",
      server_number: "0002",
    )

    CurrentHwNode.create!(coordinator: @coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: @coordinator2, ncc_node: ncc_node, version: "3.2")
    CurrentHwNode.create!(coordinator: @coordinator3, ncc_node: ncc_node, version: "3.1")
    CurrentHwNode.create!(coordinator: @coordinator4, ncc_node: ncc_node, version: "3.2 (11.19855)")

    # "Coordinator1" have the lowest vid.
    assert_equal("4", ncc_node.most_likely(:version))
  end

  test "should work if any relation of hw_nodes is given" do
    ncc_node = CurrentNccNode.new(network: @network1, vid: "0x1a0e0001"); ncc_node.save!

    hw_node = CurrentHwNode.new(
      coordinator: @coordinator1,
      ncc_node: ncc_node,
      version: "4",
    ); hw_node.save!
    HwNode.create!(descendant: hw_node, version: "3")
    HwNode.create!(descendant: hw_node, version: "3.2")
    HwNode.create!(descendant: hw_node, version: "3.1")

    assert_equal(
      HwNode.first.version,
      NccNode.most_likely(
        prop: :version,
        ncc_node: ncc_node,
        hw_nodes: HwNode.all,
      )
    )
  end
end
