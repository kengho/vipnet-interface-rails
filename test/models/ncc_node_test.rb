require "test_helper"

class NccNodesTest < ActiveSupport::TestCase
  setup do
    @network1 = networks(:network1)
    @network2 = networks(:network2)
  end

  test "shouldn't save CurrentNccNode without network" do
    current_ncc_node = CurrentNccNode.new(vid: "0x1a0e0001")
    assert_not current_ncc_node.save
  end

  test "shouldn't save DeletedNccNode without network" do
    deleted_ncc_node = DeletedNccNode.new(vid: "0x1a0e0001")
    assert_not deleted_ncc_node.save
  end

  test "shouldn't save CurrentNccNode without vid" do
    current_ncc_node = CurrentNccNode.new(network: @network1)
    assert_not current_ncc_node.save
  end

  test "shouldn't save DeletedNccNode without vid" do
    deleted_ncc_node = DeletedNccNode.new(network: @network1)
    assert_not deleted_ncc_node.save
  end

  test "shouldn't save NccNode without descendant" do
    ncc_node = NccNode.new(network: @network1, vid: "0x1a0e0001")
    assert_not ncc_node.save
  end

  test "shouldn't save with wrong vid" do
    ncc_node = NccNode.new(network: @network1, vid: "1A0E000A")
    assert_not ncc_node.save
  end

  test "shouldn't save two CurrentNccNode with same vid" do
    current_ncc_node1 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network1)
    current_ncc_node2 = CurrentNccNode.new(vid: "0x1a0e0001", network: @network1)
    assert current_ncc_node1.save
    assert_not current_ncc_node2.save
  end

  test "shouldn't save two DeletedNccNode with same vid" do
    deleted_ncc_node1 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network1)
    deleted_ncc_node2 = DeletedNccNode.new(vid: "0x1a0e0001", network: @network1)
    assert deleted_ncc_node1.save
    assert_not deleted_ncc_node2.save
  end

  test "when network destroys, all its ncc_nodes destroys" do
    CurrentNccNode.create!(vid: "0x1a0e0001", network: @network1)
    assert_equal(1, NccNode.all.size)
    @network1.destroy
    assert_equal(0, NccNode.all.size)
  end

  test "there are should be creation_date and deletion_date fields in nodes for where_date_like" do
    assert NccNode.column_names.include?("creation_date")
    assert NccNode.column_names.include?("deletion_date")
  end

  test "when new ncc_node appears, corresponding tickets should try to connect to it" do
    ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "1")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0001", ticket_id: "2")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e0002", ticket_id: "3")
    ncc_node = CurrentNccNode.new(vid: "0x1a0e0001", network: @network1); ncc_node.save!
    ticket1 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "1")
    ticket2 = Ticket.find_by(vid: "0x1a0e0001", ticket_id: "2")
    ticket3 = Ticket.find_by(vid: "0x1a0e0002", ticket_id: "3")
    assert_equal(ncc_node.id, ticket1.ncc_node_id)
    assert_equal(ncc_node.id, ticket2.ncc_node_id)
    assert_not ticket3.ncc_node_id
  end

  test "should calculate most likely version out of all" do
    ncc_node = CurrentNccNode.new(network: @network1, vid: "0x1a0e0001"); ncc_node.save!
    CurrentHwNode.create!(coordinator: coordinators(:coordinator1), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator2), ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator3), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator4), ncc_node: ncc_node, version: "4")
    assert_equal("4", ncc_node.most_likely_version)
  end

  test "should calculate most likely version out of all (mftp server)" do
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e000b",
      category: "server",
      abonent_number: "0000",
      server_number: "0002",
    )
    ncc_node = CurrentNccNode.new(
      network: @network1,
      vid: "0x1a0e0001",
      category: "client",
      server_number: "0002",
    ); ncc_node.save!
    CurrentHwNode.create!(coordinator: coordinators(:coordinator1), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator2), ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator3), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator4), ncc_node: ncc_node, version: "4")
    assert_equal("3", ncc_node.most_likely_version)
  end

  test "should calculate most likely version out of all (weights)" do
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

    CurrentHwNode.create!(coordinator: coordinators(:coordinator1), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator2), ncc_node: ncc_node, version: "3")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator3), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator4), ncc_node: ncc_node, version: "4")

    assert_equal("3", ncc_node.most_likely_version)
    # because we trust the most in coordinator2
  end

  test "should calculate most likely version out of all (lowest vid)" do
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

    CurrentHwNode.create!(coordinator: coordinators(:coordinator1), ncc_node: ncc_node, version: "4")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator2), ncc_node: ncc_node, version: "3.2")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator3), ncc_node: ncc_node, version: "3.1")
    CurrentHwNode.create!(coordinator: coordinators(:coordinator4), ncc_node: ncc_node, version: "3.2 (11.19855)")

    assert_equal("4", ncc_node.most_likely_version)
    # because coordinator1 have the lowest vid
  end
end
