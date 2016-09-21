require "faker"

namespace :db do
  # rake db:populate
  # rake db:populate[100]
  desc "Fill database with sample data"
  task :populate, [:n] => [:environment] do |_, args|
    DEFAULT_N = 200
    if args[:n]
      n = args[:n].to_i
    else
      n = DEFAULT_N
    end

    print "Destroying db...\n"
    ActiveRecord::Base.connection.tables.each do |table|
      unless ["users", "schema_migrations", "settings"].include?(table)
        table_type = table.classify.constantize
        table_type.destroy_all
      end
    end

    print "Filling Network...\n"
    Network.create!(network_vid: "6670")
    Network.create!(network_vid: "6671")

    print "Filling Coordinator...\n"
    Coordinator.create!(vid: "0x1a0e000a", network: Network.find_by(network_vid: "6670"))
    Coordinator.create!(vid: "0x1a0e000c", network: Network.find_by(network_vid: "6670"))
    Coordinator.create!(vid: "0x1a0f000a", network: Network.find_by(network_vid: "6671"))
    Coordinator.create!(vid: "0x1a0f000c", network: Network.find_by(network_vid: "6671"))

    print "Creating CurrentNccNode for coordinators...\n"
    CurrentNccNode.create!(
      vid: "0x1a0e000a",
      name: Faker::App.name,
      category: "server",
      server_number: "0001",
      abonent_number: "0000",
      network: Network.find_by(network_vid: "6670"),
    )
    CurrentNccNode.create!(
      vid: "0x1a0e000c",
      name: Faker::App.name,
      category: "server",
      server_number: "0002",
      abonent_number: "0000",
      network: Network.find_by(network_vid: "6670"),
    )
    CurrentNccNode.create!(
      vid: "0x1a0f000a",
      name: Faker::App.name,
      category: "server",
      server_number: "0001",
      abonent_number: "0000",
      network: Network.find_by(network_vid: "6671"),
    )
    CurrentNccNode.create!(
      vid: "0x1a0f000c",
      name: Faker::App.name,
      category: "server",
      server_number: "0002",
      abonent_number: "0000",
      network: Network.find_by(network_vid: "6671"),
    )

    url_templates = ["http://tickets.org/ticket_id={id}", "http://tickets2.org/ticket_id={id}"]
    url_templates.each { |url_template| TicketSystem.create!(url_template: url_template) }

    print "Filling CurrentNccNode...\n"
    n.times do |i|
      print "#{i+1}/#{n}..."
      name = Faker::Name.name
      network_vid = rand(2) == 0 ? "6670" : "6671"
      vid = "0x" + network_vid.to_i.to_s(16) + rand("0x10000".to_i(16)).to_s(16).rjust(4, "0")
      network = Network.find_by(network_vid: network_vid)
      enabled = rand(10) < 8
      creation_date = DateTime.parse(Faker::Date.backward(365).to_s)
      creation_date_accuracy = rand(10) < 8
      abonent_number = rand("0x1000".to_i(16)).to_s(16).upcase.rjust(4, "0")
      server_number = rand(2) == 0 ? "0001" : "0002"
      CurrentNccNode.create!(
        name: name,
        vid: vid,
        network: network,
        category: "client",
        enabled: enabled,
        creation_date: creation_date,
        creation_date_accuracy: creation_date_accuracy,
        abonent_number: abonent_number,
        server_number: server_number,
      )
    end

    print "Filling CurrentHwNode, NodeIp and Ticket...\n"
    versions = ["3.0-670", "3.0-671", "3.0-672", "0.3-2", "4.20"]
    CurrentNccNode.all.each_with_index do |ncc_node, i|
      print "#{i+1}/#{n+4}..."
      random_version = versions[rand(versions.size)]
      Coordinator.all.each do |coordinator|
        hw_node = CurrentHwNode.new(
          ncc_node: ncc_node,
          coordinator: coordinator,
          accessip: Faker::Internet.ip_v4_address,
          version: rand(10) < 9 ? random_version : versions[rand(versions.size)],
        )
        hw_node.save!

        NodeIp.create!(
          hw_node: hw_node,
          u32: IPv4::u32(Faker::Internet.ip_v4_address)
        )
      end

      random_ticket_ids = Array.new(rand(0...5)) { rand(100000...300000).to_s }
      random_ticket_ids.each do |random_ticket_id|
        Ticket.create!(
          ncc_node: ncc_node,
          # http://stackoverflow.com/a/5342324/6376451
          ticket_system: TicketSystem.order("RANDOM()").first,
          vid: ncc_node.vid,
          ticket_id: random_ticket_id,
        )
      end
    end
  end
end
