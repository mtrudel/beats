defmodule Beats.Metronome do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_tick() do
    GenServer.cast(__MODULE__, :do_tick)
  end

  def toggle() do
    GenServer.cast(__MODULE__, :toggle)
  end

  # Server API

  def init(_arg) do
    {:ok, timer_pid} = SchedEx.run_in(__MODULE__, :do_tick, [], 1, repeat: true, time_scale: Beats.TempoAgent)
    {:ok, %{timer_pid: timer_pid}}
  end

  def handle_cast(:do_tick, state) do
    Beats.Conductor.do_tick()
    {:noreply, state}
  end

  def handle_cast(:toggle, %{timer_pid: timer_pid} = state) do
    case timer_pid do
      nil ->
        Beats.Display.puts("Started")
        {:ok, timer_pid} = SchedEx.run_in(__MODULE__, :do_tick, [], 1, repeat: true, time_scale: Beats.TempoAgent)
        {:noreply, %{state | timer_pid: timer_pid}}
      _ -> 
        Beats.Display.puts("Stopped")
        SchedEx.cancel(timer_pid)
        {:noreply, %{state | timer_pid: nil}}
    end
  end
end
