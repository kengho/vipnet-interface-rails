require "test_helper"

class CurrentUserFlowsTest < ActionDispatch::IntegrationTest
  test "should create current_user with correct params when Ticket and Iplirconf not empty" do
    # prepare Iplifconf and Coordinator
    Coordinator.destroy_all
    changed_iplirconf = fixture_file_upload("iplirconfs/02_0x1a0e000a_changed.conf", "application/octet-stream")
    post api_v1_iplirconfs_url,
      { file: changed_iplirconf, coord_vid: "0x1a0e000a" },
      { "HTTP_AUTHORIZATION": "Token token=\"POST_HW_TOKEN\"" }
    deleted_ip_iplirconf = fixture_file_upload("iplirconfs/06_0x1a0e000d_deleted_ip.conf", "application/octet-stream")
    post api_v1_iplirconfs_url,
      { file: deleted_ip_iplirconf, coord_vid: "0x1a0e000d" },
      { "HTTP_AUTHORIZATION": "Token token=\"POST_HW_TOKEN\"" }

    # prepare Ticket
    TicketSystem.destroy_all
    Ticket.destroy_all
    ticket_system1 = TicketSystem.create!(url_template: "http://tickets.org/ticket_id={id}")
    ticket_system2 = TicketSystem.create!(url_template: "http://tickets2.org/ticket_id={id}")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e000a", ticket_id: "1")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e000b", ticket_id: "2")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e000c", ticket_id: "3")
    Ticket.create!(ticket_system: ticket_system1, vid: "0x1a0e000a", ticket_id: "4")
    Ticket.create!(ticket_system: ticket_system2, vid: "0x1a0e000b", ticket_id: "5")
    Ticket.create!(ticket_system: ticket_system2, vid: "0x1a0e000c", ticket_id: "6")

    added_client1_nodename = fixture_file_upload("nodenames/01_added_client1.doc", "application/octet-stream")
    post api_v1_nodenames_url,
      { file: added_client1_nodename, network_vid: "6670" },
      { "HTTP_AUTHORIZATION": "Token token=\"POST_ADMINISTRATOR_TOKEN\"" }
    expected_nodes = [
      {
        :vid => "0x1a0e000a",
        :name => "coordinator1",
        :enabled => true,
        :category => "server",
        :abonent_number => "0000",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.1\", \"192.0.2.3\"]",
          :"0x1a0e000d" => "[\"192.0.2.3\"]",
        },
        :accessip => { :"0x1a0e000d" => "203.0.113.4" },
        :version => {
          :"0x1a0e000a" => "3.0-670",
          :"0x1a0e000d" => "3.0-670",
        },
        :ticket => {
          :"http://tickets.org/ticket_id={id}" => "[\"1\", \"4\"]",
        },
      },
      {
        :vid => "0x1a0e000b",
        :name => "administrator",
        :enabled => true,
        :category => "client",
        :abonent_number => "0001",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.55\"]",
          :"0x1a0e000d" => "[\"192.0.2.55\"]",
        },
        :accessip => {
          :"0x1a0e000a" => "198.51.100.2",
          :"0x1a0e000d" => "203.0.113.2",
        },
        :version => {
          :"0x1a0e000a" => "3.2-673",
          :"0x1a0e000d" => "3.2-672",
        },
        :ticket => {
          :"http://tickets.org/ticket_id={id}" => "[\"2\"]",
          :"http://tickets2.org/ticket_id={id}" => "[\"5\"]",
        },
      },
      {
        :vid => "0x1a0e000c",
        :name => "client1",
        :enabled => true,
        :category => "client",
        :abonent_number => "0002",
        :server_number => "0001",
        :creation_date_accuracy => false,
        :ip => {
          :"0x1a0e000a" => "[\"192.0.2.7\"]",
          :"0x1a0e000d" => "[\"192.0.2.7\"]",
        },
        :accessip => {
          :"0x1a0e000a" => "192.0.2.7",
          :"0x1a0e000d" => "203.0.113.3",
        },
        :version => {
          :"0x1a0e000a" => "0.3-2",
          :"0x1a0e000d" => "0.3-2",
        },
        :ticket => {
          :"http://tickets.org/ticket_id={id}" => "[\"3\"]",
          :"http://tickets2.org/ticket_id={id}" => "[\"6\"]",
        },
      },
    ]
    assert_equal(expected_nodes.sort_by_vid, eval(CurrentNode.to_json_for("Nodename", "Iplirconf", "Ticket")).sort_by_vid)
  end

end
