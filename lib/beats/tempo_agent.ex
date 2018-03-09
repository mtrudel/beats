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

  def ms_per_tick() do
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
    realized_bpm = 60 * 1000 / (round(ms_per_16th(bpm)) * 4)
    error = 100.0 - (100 * (bpm / realized_bpm))

    Beats.Display.set_bpm_actual(realized_bpm)
    Beats.Display.set_bpm_goal(bpm)
    Beats.Display.set_bpm_error(error)

    {:reply, bpm, %{state | bpm: bpm}}
  end

  def handle_call(:speedup, _from, %{bpm: bpm} = state) do
    {:reply, ms_per_16th(bpm), state}
  end

  defp ms_per_16th(bpm) do
    ms_per_beat = 1000 / (bpm / 60)
    ms_per_beat / 4
  end
end
