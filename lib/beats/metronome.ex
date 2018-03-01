defmodule Beats.Metronome do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_beat() do
    GenServer.cast(__MODULE__, :do_beat)
  end

  # Server API
  
  def init(_arg) do 
    SchedEx.run_in(__MODULE__, :do_beat, [], 500, repeat: true)
    {:ok, %{}}
  end

  def handle_cast(:do_beat, state) do
    Beats.Conductor.do_beat()
    {:noreply, state}
  end
end
