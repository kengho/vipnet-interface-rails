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
      unless ["schema_migrations", "ar_internal_metadata"].include?(table)
        table_type = table.classify.constantize
        table_type.destroy_all
      end
    end

    print "Filling Network...\n"
    network1 = Network.new(network_vid: "6670"); network1.save!
    network2 = Network.new(network_vid: "6671"); network2.save!

    print "Filling Coordinator...\n"
    Coordinator.create!(vid: "0x1a0e000a", network: network1)
    Coordinator.create!(vid: "0x1a0e000c", network: network1)
    Coordinator.create!(vid: "0x1a0f000a", network: network2)
    Coordinator.create!(vid: "0x1a0f000c", network: network2)

    print "Creating CurrentNccNode for coordinators...\n"
    CurrentNccNode.create!(
      network: network1,
      vid: "0x1a0e000a",
      name: Faker::Address.city,
      enabled: true,
      category: "server",
      creation_date: get_rand_date,
      creation_date_accuracy: true,
      server_number: "0001",
      abonent_number: "0000",
    )
    CurrentNccNode.create!(
      network: network1,
      vid: "0x1a0e000c",
      name: Faker::Address.city,
      enabled: true,
      category: "server",
      creation_date: get_rand_date,
      creation_date_accuracy: true,
      server_number: "0002",
      abonent_number: "0000",
    )
    CurrentNccNode.create!(
      network: network2,
      vid: "0x1a0f000a",
      name: Faker::Address.city,
      enabled: true,
      category: "server",
      creation_date: get_rand_date,
      creation_date_accuracy: true,
      server_number: "0001",
      abonent_number: "0000",
    )
    CurrentNccNode.create!(
      network: network2,
      vid: "0x1a0f000c",
      name: Faker::Address.city,
      enabled: true,
      category: "server",
      creation_date: get_rand_date,
      creation_date_accuracy: true,
      server_number: "0002",
      abonent_number: "0000",
    )

    url_templates = ["http://tickets.org/ticket_id={id}", "http://tickets2.org/ticket_id={id}"]
    url_templates.each { |url_template| TicketSystem.create!(url_template: url_template) }

    print "Filling NccNode...\n"
    n.times do |i|
      print "#{i+1}/#{n}..."
      rand_network, rand_vid = get_rand_network_and_vid
      rand_creation_date = get_rand_date
      rand_type, rand_deletion_date = get_rand_type_and_deletion_date_after(rand_creation_date)
      ncc_node = NccNode.new(
        type: rand_type,
        name: get_rand_name,
        vid: rand_vid,
        network: rand_network,
        category: "client",
        enabled: get_rand_enabled,
        creation_date: rand_creation_date,
        creation_date_accuracy: get_rand_creation_date_accuracy,
        deletion_date: rand_deletion_date,
        abonent_number: get_rand_abonent_number,
        server_number: get_rand_server_number,
      )
      ncc_node.save!

      changing_props = [:name, :enabled, :abonent_number, :server_number]
      rand(5).times do |_|
        new_ascendant = NccNode.new(descendant: ncc_node)
        # up to 2 random props changing simultaneously
        rand_changing_props = changing_props.sample(rand(3))
        rand_changing_props.each { |p| new_ascendant[p] = send("get_rand_#{p}") }
        new_ascendant.creation_date = get_rand_date_after(ncc_node.creation_date)
        new_ascendant.save!
      end
    end

    print "Filling CurrentHwNode, NodeIp and Ticket...\n"
    CurrentNccNode.all.each_with_index do |ncc_node, i|
      # +4 corresponds to coordinators' NccNode
      print "#{i+1}/#{n+4}..."
      current_version = get_rand_version
      Coordinator.all.each do |coordinator|
        hw_node = CurrentHwNode.new(
          ncc_node: ncc_node,
          coordinator: coordinator,
          accessip: get_rand_ip,
          version: get_rand_version_near(current_version),
          creation_date: get_rand_date,
        )
        hw_node.save!

        create_random_ip_for(hw_node)

        rand(5).times do |_|
          changes = [:version, :ip, :both].sample
          new_ascendant = HwNode.new(descendant: hw_node)
          new_ascendant.creation_date = get_rand_date_after(hw_node.creation_date)
          new_ascendant.version = get_rand_version if [:version, :both].include?(changes)
          new_ascendant.save!
          create_random_ip_for(new_ascendant) if [:ip, :both].include?(changes)
        end
      end

      rand_ticket_ids = Array.new(rand(0...5)) { rand(100000...400000).to_s }
      rand_ticket_ids.each do |rand_ticket_id|
        Ticket.create!(
          ncc_node: ncc_node,
          ticket_system: TicketSystem.order("RANDOM()").first,
          vid: ncc_node.vid,
          ticket_id: rand_ticket_id,
        )
      end
    end

    print "\nDone.\n"
  end

  def get_rand_type_and_deletion_date_after(creation_date)
    if rand(10) < 8
      ["CurrentNccNode", nil]
    else
      ["DeletedNccNode", get_rand_date_after(creation_date)]
    end
  end

  def get_rand_name
    Faker::Name.name
  end

  def get_rand_network_and_vid
    rand_network = Network.order("RANDOM()").first
    rand_vid = "0x" + rand_network.network_vid.to_i.to_s(16) + rand("0x10000".to_i(16)).to_s(16).rjust(4, "0")
    # as long as n is significantly smaller than 0x10000, recursion is ok (0 < number_of_steps < 1)
    if NccNode.find_by(vid: rand_vid)
      get_rand_network_and_vid
    else
      [rand_network, rand_vid]
    end
  end

  def get_rand_enabled
    rand(100) < 95
  end

  def get_rand_date
    DateTime.parse(Faker::Time.backward(7).to_s)
  end

  def get_rand_date_after(date)
    Faker::Time.between(date, Time.now)
  end

  def get_rand_creation_date_accuracy
    rand(10) < 8
  end

  def get_rand_abonent_number
    rand("0x1000".to_i(16)).to_s(16).upcase.rjust(4, "0")
  end

  def get_rand_server_number
    rand(2) == 0 ? "0001" : "0002"
  end

  def get_rand_ip
    Faker::Internet.ip_v4_address
  end

  def create_random_ip_for(hw_node)
    NodeIp.create!(
      hw_node: hw_node,
      u32: IPv4::u32(get_rand_ip),
    )
  end

  def get_rand_version
    version_list = ["3.0-670", "3.0-671", "3.0-672", "4.20"]
    version_list_expanded = version_list*10 + ["0.3-2"]
    version_list_expanded.sample
  end

  def get_rand_version_near(version)
    rand(10) < 9 ? version : get_rand_version
  end
end
