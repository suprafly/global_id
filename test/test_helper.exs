ExUnit.start()

defmodule Benchmark do
  def get_elapsed_seconds(func) do
    {ms, result} = :timer.tc(func)
    [seconds: (ms / 1_000_000), result: result]
  end
end

defmodule MicroClock do
  @moduledoc """
  A genserver used to test unique global id creation.
  """
  use GenServer

  @one_ms 1

  def init(_opts) do
    {:ok, %{data: [], finished: false}}
  end

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start(func) do
    start_link()
    start_clock(func)
  end

  def start_clock(func, reqs_per_ms \\ 100, num_reqs \\ 1000) do
    GenServer.cast(__MODULE__, {:start_clock, func, reqs_per_ms, num_reqs})
  end

  def run(func, reqs_per_ms \\ 100, num_reqs \\ 1000) do
    _ = start_clock(func, reqs_per_ms, num_reqs)
    get_result() |> while_running()
  end

  def while_running(:still_running) do
    get_result() |> while_running()
  end

  def while_running(result) do
    result
  end

  def get_result() do
    GenServer.call(__MODULE__, :get)
  end

  def get_result_num_unique() do
    GenServer.call(__MODULE__, :get)
    |> Enum.uniq()
    |> length()
  end

  def handle_call(:get, _from, %{data: list, finished: finished} = state) do
    case finished do
      true -> {:reply, List.flatten(list), state}
      false -> {:reply, :still_running, state}
    end
  end

  def handle_cast({:start_clock, func, reqs_per_ms, num_reqs}, _) do
    Process.send_after(__MODULE__, {:tick, func, reqs_per_ms, num_reqs - 1}, @one_ms)
    {:noreply, %{data: [], finished: false}}
  end

  def handle_info({:tick, func, reqs_per_ms, 0}, %{data: list}) do
    result = 1..reqs_per_ms
    |> Enum.map(fn(_) -> Task.async(fn -> func.() end) end)
    |> Enum.map(fn(task) -> Task.await(task) end)

    {:noreply, %{data: [result | list], finished: true}}
  end

  def handle_info({:tick, func, reqs_per_ms, num_reqs}, %{data: list, finished: finished}) do
    Process.send_after(__MODULE__, {:tick, func, reqs_per_ms, num_reqs - 1}, @one_ms)
    result = 1..reqs_per_ms
    |> Enum.map(fn(_) -> Task.async(fn -> func.() end) end)
    |> Enum.map(fn(task) -> Task.await(task) end)
    {:noreply, %{data: [result | list], finished: finished}}
  end
end
