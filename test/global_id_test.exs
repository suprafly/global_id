defmodule GlobalIdTest do
  use ExUnit.Case
  doctest GlobalId

  import Benchmark, only: [get_elapsed_seconds: 1]

  test "test binary_id/3" do
    node_id = GlobalId.node_id()
    ts = GlobalId.get_timestamp()
    seq = GlobalId.get_sequence_number()

    bin_id = GlobalId.binary_id(node_id, ts, seq)
    assert is_binary(bin_id)
    assert bit_size(bin_id) == 64
    assert bin_id == << <<node_id::size(10)>>, <<ts::size(22)>>, <<seq::size(32)>> >>
  end

  test "test 100_000 requests as fast as possible (usually under a second)" do
    num_ids = 100_000
    [seconds: secs, result: total] =
    get_elapsed_seconds(fn ->
      1..num_ids
      |> Enum.map(fn(_) -> Task.async(fn -> GlobalId.get_id() end) end)
      |> Enum.map(fn(task) -> Task.await(task) end)
    end)

    total_unique = Enum.uniq(total)
    assert length(total_unique) == num_ids
    assert secs <= 1
  end

  test "test 100_000 requests - 100 per millisecond, every millisecond" do
    # Note: The genserver may add a bit of overhead in message passing
    #       and so this may take slightly longer than a second.
    _ = MicroClock.start_link()
    total = MicroClock.run(fn -> GlobalId.get_id() end, 100, 1000)
    total_unique = Enum.uniq(total)
    assert length(total_unique) == 100_000
  end
end
