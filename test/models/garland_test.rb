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

    @h1 = { a: "a1", b: "b1" }
    @h2 = { a: "a2", b: "b1" }
    @h3 = { a: "a3", b: "b1" }
    @h4 = { a: "a4", b: "b1" }
    @h5 = { a: "a5", b: "b1" }
    @h6 = { a: "a6", b: "b1" }
  end

  test "should not save without entity" do
    s = Storage.new(entity: nil, entity_type: Garland::DIFF)
    assert_not s.save
  end

  test "should not save without entity_type" do
    s = Storage.new(entity: "{}", entity_type: nil)
    assert_not s.save
  end

  test "should not save more than one record with next is nil" do
    Storage.new(entity: "{}", entity_type: Garland::DIFF, next: nil).save
    s1 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: nil)
    assert_not s1.save
    s2 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: 1)
    assert s2.save
  end

  test "should not save more than one record with next is nil (belongs)" do
    StorageBelongsNetwork.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: nil).save
    s = StorageBelongsNetwork.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: nil)
    assert_not s.save
  end

  test "should save more than one record with next is nil if it belongs to different objects" do
    StorageBelongsNetwork.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: 1).save
    s = StorageBelongsCoordinator.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @coordinator1.id, belongs_to_type: "Coordinator", next: nil)
    assert s.save
  end

  test "should not push not hashes" do
    s = Storage.push("not hash")
    assert_not s
  end

  test "should push hashes" do
    s1, _ = Storage.push(@h1)
    assert_equal(HashDiffSym.diff({}, @h1), s1)
    last = Storage.last
    s1_id = last.id
    assert_equal(@h1.to_s, last.entity)
    assert_equal(Garland::SNAPSHOT, last.entity_type)
    assert_equal(nil, last.previous)
    assert_equal(nil, last.next)

    s2, _ = Storage.push(@h2)
    assert_equal(HashDiffSym.diff(@h1, @h2), s2)
    last = Storage.last
    s2_id = last.id
    assert_equal(HashDiffSym.diff(@h1, @h2).to_s, last.entity)
    assert_equal(s1_id, last.previous)
    assert_equal(nil, last.next)
    assert_equal(Garland::DIFF, last.entity_type)
    assert_equal(s1_id, Storage.find_by(next: s2_id).id)
    assert_equal(s2_id, Storage.find_by(previous: s1_id).id)

    s3, _ = Storage.push(@h3)
    assert_equal(HashDiffSym.diff(@h2, @h3), s3)
    last = Storage.last
    s3_id = last.id
    assert_equal(HashDiffSym.diff(@h2, @h3).to_s, last.entity)
  end

  test "should not push if table should belong to something but it is not defined" do
    s, _ = StorageBelongsNetwork.push(@h1)
    assert_not s
  end

  test "should push to table which belong to something" do
    s, _ = StorageBelongsNetwork.push(hash: @h1, belongs_to: @network1)
    assert_equal(HashDiffSym.diff({}, @h1), s)
  end

  test "should be able to make snapshots" do
    Storage.push(@h1)
    Storage.push(@h2)
    assert_equal(@h2, eval(Storage.snapshot.entity))
    Storage.push(@h3)
    assert_equal(@h3, eval(Storage.snapshot.entity))
  end

  test "snapshot should return nil if there are stack errors" do
    Storage.push(@h1)
    e = Storage.first
    e.next = Garland::NEXT_ID_PENDING
    e.save
    assert_equal(nil, Storage.snapshot)
  end

  test "should be able to make snapshots (belongs)" do
    StorageBelongsNetwork.push(hash: @h1, belongs_to: @network1)
    StorageBelongsNetwork.push(hash: @h2, belongs_to: @network1)
    assert_equal(@h2, eval(StorageBelongsNetwork.snapshot(@network1).entity))
    StorageBelongsNetwork.push(hash: @h3, belongs_to: @network1)
    assert_equal(@h3, eval(StorageBelongsNetwork.snapshot(@network1).entity))

    StorageBelongsNetwork.push(hash: @h1, belongs_to: @network2)
    StorageBelongsNetwork.push(hash: @h2, belongs_to: @network2)
    assert_equal(@h2, eval(StorageBelongsNetwork.snapshot(@network2).entity))
    StorageBelongsNetwork.push(hash: @h3, belongs_to: @network2)
    assert_equal(@h3, eval(StorageBelongsNetwork.snapshot(@network2).entity))
  end

  test "should be able to tell is there are any records belongs to given" do
    assert_not StorageBelongsNetwork.any?(@network1)
    StorageBelongsNetwork.push(hash: @h1, belongs_to: @network1)
    assert StorageBelongsNetwork.any?(@network1)
  end

  test "should not save if belongs_to_type doesn't matches table set in belongs_to" do
    StorageBelongsNetwork.push(hash: "{}", belongs_to: @network1)
    n = StorageBelongsNetwork.first
    n.belongs_to_type = "Something"
    assert_not n.save
  end

  test "should not save empty diffs" do
    Storage.push(@h1)
    Storage.push(@h1)
    assert_equal(1, Storage.all.size)
  end
end
