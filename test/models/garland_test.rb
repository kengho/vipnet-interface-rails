require "test_helper"

class GarlandsTest < ActiveSupport::TestCase
  setup do
    class Storage < Garland
    end

    class StorageBelongs < Garland
      belongs_to :network, foreign_key: "belongs_to_id"
      validates :belongs_to_id, presence: true
    end

    @network1 = networks(:network1)
    @network2 = networks(:network2)

    @h1 = { a: "a1", b: "b1" }
    @h2 = { a: "a2", b: "b1" }
    @h3 = { a: "a3", b: "b1" }
    @h4 = { a: "a4", b: "b1" }
    @h5 = { a: "a5", b: "b1" }
    @h6 = { a: "a6", b: "b1" }
  end

  test "validations" do
    s1 = Storage.new(entity: "{}", entity_type: nil)
    s2 = Storage.new(entity: nil, entity_type: Garland::SNAPSHOT)
    s3 = Storage.new(entity: "{}", entity_type: Garland::DIFF)
    s4 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: nil)
    s5 = Storage.new(entity: "{}", entity_type: Garland::DIFF, next: 1)
    assert_not s1.save
    assert_not s2.save
    assert s3.save
    assert_not s4.save
    assert s5.save
  end

  test "validations belongs" do
    s1 = StorageBelongs.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: nil)
    s2 = StorageBelongs.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: nil)
    s3 = StorageBelongs.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "Network", next: 1)
    s4 = StorageBelongs.new(entity: "{}", entity_type: Garland::SNAPSHOT, belongs_to_id: @network1.id, belongs_to_type: "NotNetwork", next: nil)
    assert s1.save
    assert_not s2.save
    assert s3.save
    assert s4.save
  end

  test "push" do
    s0 = Storage.push("not hash")
    assert_not s0

    s1 = Storage.push(@h1)
    assert s1
    last = Storage.last
    s1_id = last.id
    assert_equal(@h1.to_s, last.entity)
    assert_equal(Garland::SNAPSHOT, last.entity_type)
    assert_equal(nil, last.previous)
    assert_equal(nil, last.next)

    s2 = Storage.push(@h2)
    assert s2
    last = Storage.last
    s2_id = last.id
    assert_equal(HashDiffSym.diff(@h1, @h2).to_s, last.entity)
    assert_equal(s1_id, last.previous)
    assert_equal(nil, last.next)
    assert_equal(Garland::DIFF, last.entity_type)
    assert_equal(s1_id, Storage.find_by(next: s2_id).id)
    assert_equal(s2_id, Storage.find_by(previous: s1_id).id)

    s3 = Storage.push(@h3)
    assert s3
    last = Storage.last
    s3_id = last.id
    assert_equal(HashDiffSym.diff(@h2, @h3).to_s, last.entity)
  end

  test "push belongs" do
    s0 = StorageBelongs.push(@h1)
    assert_not s0

    s1 = StorageBelongs.push(hash: @h1, belongs_to: @network1)
    assert s1
  end

  test "snapshot" do
    Storage.push(@h1)
    Storage.push(@h2)
    assert_equal(@h2, eval(Storage.snapshot.entity))
    Storage.push(@h3)
    assert_equal(@h3, eval(Storage.snapshot.entity))

    # make little mess
    last = Storage.last
    last.next = Garland::NEXT_ID_PENDING
    last.save
    assert_equal(nil, Storage.snapshot)
  end

  test "snapshot belongs" do
    StorageBelongs.push(hash: @h1, belongs_to: @network1)
    StorageBelongs.push(hash: @h2, belongs_to: @network1)
    assert_equal(@h2, eval(StorageBelongs.snapshot(@network1).entity))
    StorageBelongs.push(hash: @h3, belongs_to: @network1)
    assert_equal(@h3, eval(StorageBelongs.snapshot(@network1).entity))

    StorageBelongs.push(hash: @h1, belongs_to: @network2)
    StorageBelongs.push(hash: @h2, belongs_to: @network2)
    assert_equal(@h2, eval(StorageBelongs.snapshot(@network2).entity))
    StorageBelongs.push(hash: @h3, belongs_to: @network2)
    assert_equal(@h3, eval(StorageBelongs.snapshot(@network2).entity))
  end
end