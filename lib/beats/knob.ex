defmodule Beats.Knob do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(_arg) do
    {:ok, midi_pid} = PortMidi.open(:input, "Teensy MIDI")
    PortMidi.listen(midi_pid, self())
    {:ok, %{midi_pid: midi_pid}}
  end

  def handle_info({_pid, [{{_status, 16 = _channel, 0}, _timestamp} | _]}, state) do
    Beats.TempoAgent.slow_down()
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 16 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.TempoAgent.speed_up()
    {:noreply, state}
  end

  def handle_info({_pid, events}, state) do
    {:noreply, state}
  end
end
