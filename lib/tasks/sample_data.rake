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

    ActiveRecord::Base.connection.tables.each do |table|
      unless ["users", "schema_migrations", "settings"].include?(table)
        table_type = table.classify.constantize
        table_type.destroy_all
      end
    end

    Network.create!(network_vid: "6670")
    Network.create!(network_vid: "6671")

    Coordinator.create!(vid: "0x1a0e000a", network: Network.find_by(network_vid: "6670"))
    Coordinator.create!(vid: "0x1a0e000c", network: Network.find_by(network_vid: "6670"))
    Coordinator.create!(vid: "0x1a0f000a", network: Network.find_by(network_vid: "6671"))
    Coordinator.create!(vid: "0x1a0f000c", network: Network.find_by(network_vid: "6671"))

    CurrentNode.create!(
      vid: "0x1a0e000a",
      name: Faker::App.name,
      category: "server",
      server_number: "0001",
      network: Network.find_by(network_vid: "6670"),
    )
    CurrentNode.create!(
      vid: "0x1a0e000c",
      name: Faker::App.name,
      category: "server",
      server_number: "0002",
      network: Network.find_by(network_vid: "6670"),
    )
    CurrentNode.create!(
      vid: "0x1a0f000a",
      name: Faker::App.name,
      category: "server",
      server_number: "0001",
      network: Network.find_by(network_vid: "6671"),
    )
    CurrentNode.create!(
      vid: "0x1a0f000c",
      name: Faker::App.name,
      category: "server",
      server_number: "0002",
      network: Network.find_by(network_vid: "6671"),
    )

    url_templates = ["http://tickets.org/ticket_id={id}", "http://tickets2.org/ticket_id={id}"]
    url_templates.each do |url_template|
      TicketSystem.create!(url_template: url_template)
    end

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
      ticket = {}
      url_templates.each do |url_template|
        random_ticket_ids = Array.new(rand(1...5)) { rand(100000...300000).to_s }
        if rand(2) == 0
          ticket[url_template] = random_ticket_ids.to_s
          random_ticket_ids.each do |random_ticket_id|
            ts = TicketSystem.find_by(url_template: url_template)
            Ticket.create!(ticket_system: ts, vid: vid, ticket_id: random_ticket_id, )
          end
        end
      end
      versions = ["3.0-670", "3.0-671", "3.0-672", "0.3-2", "4.20"]
      ip = {}
      accessip = {}
      version = {}
      version_decoded = {}
      first_version = ""
      Coordinator.all.each_with_index do |coord, i|
        ip[coord.vid] = [Faker::Internet.ip_v4_address]
        accessip[coord.vid] = Faker::Internet.ip_v4_address
        if i == 0
          version[coord.vid] = versions[rand(versions.size)]
          first_version = version[coord.vid]
        else
          versions_minus_first = versions - [first_version]
          version[coord.vid] = rand(10) < 8 ? first_version : versions_minus_first[rand(versions_minus_first.size)]
        end
        version_decoded[coord.vid] = Node.version_decode(version[coord.vid])
      end
      CurrentNode.create!(
        name: name,
        vid: vid,
        network: network,
        category: "client",
        enabled: enabled,
        creation_date: creation_date,
        creation_date_accuracy: creation_date_accuracy,
        abonent_number: abonent_number,
        server_number: server_number,
        ticket: ticket,
        ip: ip,
        accessip: accessip,
        version: version,
        version_decoded: version_decoded,
      )
    end
  end
end
