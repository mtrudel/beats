defmodule Beats.TempoAgent do
  use GenServer

  # Client API

  def start_link(bpm) do
    GenServer.start_link(__MODULE__, bpm, name: __MODULE__)
  end

  def slow_down(by \\ 2) do
    GenServer.call(__MODULE__, {:adjust_bpm, -by})
  end

  def speed_up(by \\ 2) do
    GenServer.call(__MODULE__, {:adjust_bpm, by})
  end

  def set_bpm(bpm) do
    GenServer.call(__MODULE__, {:set_bpm, bpm})
  end

  def speedup() do
    GenServer.call(__MODULE__, :speedup)
  end

  # Server API
  
  def init(bpm) do 
    {:ok, %{bpm: bpm}}
  end

  def handle_call({:adjust_bpm, by}, from, %{bpm: bpm} = state) do
    handle_call({:set_bpm, bpm + by}, from, state)
  end

  def handle_call({:set_bpm, bpm}, _from, state) do
    bpm = max(bpm, 10)
    IO.puts "Setting to #{bpm} BPM"
    {:reply, bpm, %{state | bpm: bpm}}
  end

  def handle_call(:speedup, _from, %{bpm: bpm} = state) do
    ms_per_beat = 1000 / (bpm / 60)
    {:reply, 1 / ms_per_beat, state}
  end
end
