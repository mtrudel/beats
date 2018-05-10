defmodule Beats.StatsTracker do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_stats() do
    GenServer.call(__MODULE__, :do_stats)
  end

  def set_timer_pid(pid) do
    GenServer.call(__MODULE__, {:set_timer_pid, pid})
  end

  # Server API

  def init(_arg) do
    SchedEx.run_in(__MODULE__, :do_stats, [], 100, repeat: true)
    {:ok, %{timer_pid: nil}}
  end

  def handle_call(:do_stats, _from, %{timer_pid: timer_pid} = state) when not is_nil(timer_pid) do
    timer_pid |> SchedEx.stats() |> Beats.Display.update_stats()
    {:reply, :ok, state}
  end

  def handle_call(:do_stats, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:set_timer_pid, timer_pid}, _from, state) do
    {:reply, :ok, %{state | timer_pid: timer_pid}}
  end
end
