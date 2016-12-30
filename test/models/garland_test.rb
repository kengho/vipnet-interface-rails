require "test_helper"

class GarlandsTest < ActiveSupport::TestCase
  setup do
    class Storage < Garland
    end

    class StorageBelongsNetwork < GarlandBelongs
      belongs_to :network
    end

    class StorageBelongsCoordinator < GarlandBelongs
      belongs_to :coordinator
    end

    Storage.destroy_all
    StorageBelongsNetwork.destroy_all
    StorageBelongsCoordinator.destroy_all

    @network1 = networks(:network1)
    @network2 = networks(:network2)
    @coordinator1 = coordinators(:coordinator1)

    @hash1 = { a: "a1", b: "b1" }
    @hash2 = { a: "a2", b: "b1" }
    @hash3 = { a: "a3", b: "b1" }
  end

  test "should not save without entity" do
    item = Storage.new(entity: nil, entity_type: Garland::DIFF)
    assert_not item.save
  end

  test "should not save without entity_type" do
    item = Storage.new(entity: "{}", entity_type: nil)
    assert_not item.save
  end

  test "should not save more than one record with next is nil" do
    Storage.create!(entity: "{}", entity_type: Garland::DIFF, next: nil, previous: 1)
    item2 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: nil, previous: 1)
    assert_not item2.save
  end

  test "should not save more than one record with previous is nil" do
    Storage.create!(entity: "{}", entity_type: Garland::DIFF, next: 1, previous: nil)
    item2 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: 1, previous: nil)
    assert_not item2.save
  end

  test "should not save more than one record with next is nil (belongs)" do
    StorageBelongsNetwork.create!(
      entity: "{}",
      entity_type: Garland::SNAPSHOT,
      belongs_to_id: @network1.id,
      belongs_to_type: "Network",
      next: nil,
    )
    item2 = StorageBelongsNetwork.new(
      entity: "{}",
      entity_type: Garland::SNAPSHOT,
      belongs_to_id: @network1.id,
      belongs_to_type: "Network",
      next: nil,
    )
    assert_not item2.save
  end

  test "should save more than one record with next is nil if it belongs to different objects" do
    StorageBelongsNetwork.create!(
      entity: "{}",
      entity_type: Garland::SNAPSHOT,
      belongs_to_id: @network1.id,
      belongs_to_type: "Network",
      next: 1,
    )
    item2 = StorageBelongsCoordinator.new(
      entity: "{}",
      entity_type: Garland::SNAPSHOT,
      belongs_to_id: @coordinator1.id,
      belongs_to_type: "Coordinator",
      next: nil,
    )
    assert item2.save
  end

  test "should not push not hashes" do
    item = Storage.push("not hash")
    assert_not item
  end

  test "should push hashes" do
    diff1 = Storage.push(@hash1)
    assert_equal(HashDiffSym.diff({}, @hash1), eval(diff1.entity))
    assert Storage.continuous?(nil)

    diff2 = Storage.push(@hash2)
    assert_equal(HashDiffSym.diff(@hash1, @hash2), eval(diff2.entity))
    assert Storage.continuous?(nil)

    diff3 = Storage.push(@hash3)
    assert_equal(HashDiffSym.diff(@hash2, @hash3), eval(diff3.entity))
    assert Storage.continuous?(nil)
  end

  test "should create and restore savepoints on errors" do
  end

  test "should not push if table should belong to something but it is not defined" do
    diff1 = StorageBelongsNetwork.push(@hash1)
    assert_not diff1
  end

  test "should push to table which belong to something" do
    diff1 = StorageBelongsNetwork.push(hash: @hash1, belongs_to: @network1)
    assert_equal(HashDiffSym.diff({}, @hash1), eval(diff1.entity))
  end

  test "should not save if belongs_to_type doesn't matches table set in belongs_to" do
    StorageBelongsNetwork.push(hash: {}, belongs_to: @network1)
    item1 = StorageBelongsNetwork.first
    item1.belongs_to_type = "SomeOtherModel"
    assert_not item1.save
  end

  test "should not save empty diffs" do
    Storage.push(@hash1)
    Storage.push(@hash1)

    # head, first_diff, tail
    assert_equal(3, Storage.all.size)
  end

  test "should be able to get head" do
    Storage.push(@hash1)
    assert Storage.head
  end

  test "should be able to get tail" do
    Storage.push(@hash1)
    assert Storage.tail
  end
end
