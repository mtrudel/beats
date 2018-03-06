defmodule Beats.Metronome do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_tick() do
    GenServer.cast(__MODULE__, :do_tick)
  end

  # Server API
  
  def init(_arg) do 
    SchedEx.run_in(__MODULE__, :do_tick, [], 1, repeat: true, time_scale: Beats.TempoAgent)
    {:ok, %{}}
  end

  def handle_cast(:do_tick, state) do
    Beats.Conductor.do_tick()
    {:noreply, state}
  end
end
