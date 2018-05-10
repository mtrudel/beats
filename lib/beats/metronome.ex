defmodule Beats.Metronome do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_tick() do
    GenServer.cast(__MODULE__, :do_tick)
  end

  def slow_down(by \\ 2) do
    Beats.TempoAgent.slow_down(by)
  end

  def speed_up(by \\ 2) do
    Beats.TempoAgent.speed_up(by)
  end

  def set_bpm(bpm) do
    Beats.TempoAgent.set_bpm(bpm)
  end

  def swing_less(by \\ 0.01) do
    Beats.TempoAgent.swing_less(by)
  end

  def swing_more(by \\ 0.01) do
    Beats.TempoAgent.swing_more(by)
  end

  def set_swing(swing) do
    Beats.TempoAgent.set_swing(swing)
  end

  def toggle() do
    GenServer.cast(__MODULE__, :toggle)
  end

  # Server API

  def init(_arg) do
    {:ok, _} = Beats.TempoAgent.start_link()
    {:ok, %{timer_pid: nil}}
  end

  def handle_cast(:do_tick, %{timer_pid: timer_pid} = state) do
    Beats.Conductor.do_tick() |> Beats.TempoAgent.set_tick()
    {:noreply, state}
  end

  def handle_cast(:toggle, %{timer_pid: timer_pid} = state) do
    case timer_pid do
      nil ->
        Beats.Display.set_playing(true)

        {:ok, timer_pid} =
          SchedEx.run_in(__MODULE__, :do_tick, [], 1, repeat: true, time_scale: Beats.TempoAgent)

        Beats.StatsTracker.set_timer_pid(timer_pid)

        {:noreply, %{state | timer_pid: timer_pid}}

      _ ->
        Beats.Display.set_playing(false)
        Beats.StatsTracker.set_timer_pid(nil)
        SchedEx.cancel(timer_pid)
        {:noreply, %{state | timer_pid: nil}}
    end
  end
end
