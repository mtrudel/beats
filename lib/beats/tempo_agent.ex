defmodule Beats.TempoAgent do
  use GenServer

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
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

  def set_tick(tick) do
    GenServer.call(__MODULE__, {:set_tick, tick})
  end

  def swing_less(by \\ 0.01) do
    GenServer.call(__MODULE__, {:adjust_swing, -by})
  end

  def swing_more(by \\ 0.01) do
    GenServer.call(__MODULE__, {:adjust_swing, by})
  end

  def set_swing(swing) do
    GenServer.call(__MODULE__, {:set_swing, swing})
  end

  def speedup() do
    GenServer.call(__MODULE__, :speedup)
  end

  # Server API

  def init(_) do
    {:ok, %{bpm: 0, swing: 0.5, tick: 0}}
  end

  def handle_call({:adjust_bpm, by}, from, %{bpm: bpm} = state) do
    handle_call({:set_bpm, bpm + by}, from, state)
  end

  def handle_call({:set_bpm, bpm}, _from, state) do
    bpm = max(bpm, 10)
    realized_bpm = 60 * 1000 / (round(ms_per_16th(bpm)) * 4)
    error = 100.0 - 100 * (bpm / realized_bpm)

    Beats.Display.set_bpm_actual(realized_bpm)
    Beats.Display.set_bpm_goal(bpm)
    Beats.Display.set_bpm_error(error)

    {:reply, bpm, %{state | bpm: bpm}}
  end

  def handle_call({:set_tick, tick}, _from, state) do
    {:reply, :ok, %{state | tick: tick}}
  end

  def handle_call({:adjust_swing, by}, from, %{swing: swing} = state) do
    handle_call({:set_swing, swing + by}, from, state)
  end

  def handle_call({:set_swing, swing}, _from, state) do
    swing = min(max(swing, 0.01), 0.99)
    Beats.Display.set_swing(swing)
    {:reply, swing, %{state | swing: swing}}
  end

  def handle_call(:speedup, _from, %{bpm: bpm, swing: swing, tick: tick} = state) do
    speedup =
      case rem(tick, 2) do
        0 -> 1 / (2 * swing * ms_per_16th(bpm))
        1 -> 1 / ((2 - 2 * swing) * ms_per_16th(bpm))
      end

    {:reply, speedup, state}
  end

  defp ms_per_16th(bpm) do
    ms_per_beat = 1000 / (bpm / 60)
    ms_per_beat / 4
  end
end
