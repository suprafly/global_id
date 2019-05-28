 defmodule GlobalId do
  @moduledoc """
  GlobalId module contains an implementation of a guaranteed globally unique id system.
  """
  @id_bits 10
  @ts_bits 22
  @seq_bits 32
  @node_id Enum.random(0..1024)
  @custom_epoch 1420070400000

  @doc """
  """
  @spec get_id() :: non_neg_integer
  def get_id() do
    node_id()
    |> binary_id(get_timestamp(), get_sequence_number())
    |> to_integer()
  end

  def binary_id(node_id, ts, seq) do
    # Builds the binary form of the id, inspired by the Twitter Snowflake algorithm,
    # explained in this blog post: https://www.callicoder.com/distributed-unique-id-sequence-number-generator/
    << <<node_id::size(@id_bits)>>, <<ts::size(@ts_bits)>>, <<seq::size(@seq_bits)>> >>
  end

  defp to_integer(binary_id) do
    binary_id |> :binary.decode_unsigned()
  end

  @doc """
  Returns your node id as an integer.
  It will be greater than or equal to 0 and less than or equal to 1024.
  It is guaranteed to be globally unique.
  """
  @spec node_id() :: non_neg_integer
  def node_id() do
    @node_id
  end

  @doc """
  Returns a positive integer via the Erlang `unique_integer` function.

  This integer is guaranteed to be unique, and more information can be found:
  http://erlang.org/doc/efficiency_guide/advanced.html#unique_integers
  """
  def get_sequence_number() do
    :erlang.unique_integer([:positive])
  end

  @doc """
  Returns timestamp in nanoseconds.
  """
  @spec get_timestamp() :: non_neg_integer
  def get_timestamp() do
    System.system_time(:second) - @custom_epoch
  end
end
