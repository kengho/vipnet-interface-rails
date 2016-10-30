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
    CurrentHwNode.create!(@coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(@coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator4, ncc_node: ncc_node, version: "4")
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

    CurrentHwNode.create!(@coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(@coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator4, ncc_node: ncc_node, version: "4")
    assert_equal("3", ncc_node.most_likely(:version))
    # because coordinator2 is ncc_node's mftp_server
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

    CurrentHwNode.create!(@coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator2, ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(@coordinator3, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator4, ncc_node: ncc_node, version: "4")

    assert_equal("3", ncc_node.most_likely(:version))
    # because we trust the most in coordinator2
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

    CurrentHwNode.create!(@coordinator1, ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(@coordinator2, ncc_node: ncc_node, version: "3.2")
    CurrentHwNode.create!(@coordinator3, ncc_node: ncc_node, version: "3.1")
    CurrentHwNode.create!(@coordinator4, ncc_node: ncc_node, version: "3.2 (11.19855)")

    assert_equal("4", ncc_node.most_likely(:version))
    # because coordinator1 have the lowest vid
  end
end
