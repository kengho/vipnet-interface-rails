require "test_helper"

class NodenamesTest < ActiveSupport::TestCase
  test "validations" do
    nodename1 = Nodename.new(network_id: nil)
    assert_not nodename1.save
  end

  test "changed_records" do
    nodename1 = Nodename.new(network_id: networks(:network1).id)
    nodename1.save!
    initial_records = {
      "1A0E000B" => {
        :name => "administrator",
        :enabled => true,
        :category => :client,
        :server_number => "0001",
        :abonent_number => "0001",
        :id => "1A0E000B",
      },
      "1A0E000A" => {
        :name => "coordinator1",
        :enabled => true,
        :category => :server,
        :server_number => "0001",
        :abonent_number => "0000",
        :id => "1A0E000A",
      },
      "1A0E0000" => {
        :name => "Вся сеть",
        :enabled => true,
        :category => :group,
        :server_number => "0000",
        :abonent_number => "0000",
        :id => "1A0E0000",
      },
    }
    nodename2 = Nodename.new(network_id: networks(:network1).id)
    nodename2.records = initial_records

    initial_records_normalized = Hash.new
    initial_records.each do |id, record|
      normalized_id = VipnetParser::id(id)[0]
      initial_records_normalized[normalized_id] = record
    end

    assert_equal(initial_records_normalized, nodename1.changed_records(nodename2))

    nodename1.records = initial_records
    nodename1.save!
    changed_records1 = {
      "1A0E000B" => {
        :name => "administrator_changed",
        :enabled => true,
        :category => :client,
        :server_number => "0001",
        :abonent_number => "0001",
        :id => "1A0E000B",
      },
      "1A0E000A" => {
        :name => "coordinator1",
        :enabled => true,
        :category => :server,
        :server_number => "0001",
        :abonent_number => "0000",
        :id => "1A0E000A",
      },
      "1A0E0000" => {
        :name => "Вся сеть",
        :enabled => true,
        :category => :group,
        :server_number => "0000",
        :abonent_number => "0000",
        :id => "1A0E0000",
      },
    }
    nodename2.records = changed_records1

    assert_equal({ "0x1a0e000b" => { :name => "administrator_changed" }}, nodename1.changed_records(nodename2))

    changed_records2 = {
      "1A0E000E" => {
        :name => "coordinator2",
        :id => "1A0E000E",
      },
    }
    nodename2.records = changed_records2

    assert_equal({
      "0x1a0e000e" => {
        :name => "coordinator2",
        :id => "1A0E000E",
      },
    }, nodename1.changed_records(nodename2))

    changed_records3 = {
      "1A0E000B" => {
        :server_number => "0002",
        :abonent_number => "0002",
      },
    }
    nodename2.records = changed_records3

    assert_equal({
      "0x1a0e000b" => {
        :server_number => "0002",
        :abonent_number => "0002",
      },
    }, nodename1.changed_records(nodename2))
  end
end
