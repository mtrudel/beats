defmodule Beats.Knob do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(_arg) do
    if PortMidi.devices()
    |> Map.get(:input)
    |> Enum.map(&(&1.name))
    |> Enum.member?("Teensy MIDI") do
      {:ok, midi_pid} = PortMidi.open(:input, "Teensy MIDI")
      PortMidi.listen(midi_pid, self())
      {:ok, %{midi_pid: midi_pid}}
    else
      :ignore
    end
  end

  def handle_info({_pid, [{{_status, 16 = _channel, 0}, _timestamp} | _]}, state) do
    Beats.TempoAgent.slow_down()
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 16 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.TempoAgent.speed_up()
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 18 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.Metronome.toggle()
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 19 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.Display.puts("Button 1 Pressed")
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 20 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.Display.puts("Button 2 Pressed")
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 21 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.Display.puts("Button 3 Pressed")
    {:noreply, state}
  end

  def handle_info({_pid, [{{_status, 22 = _channel, 127}, _timestamp} | _]}, state) do
    Beats.Display.puts("Button 4 Pressed")
    {:noreply, state}
  end

  def handle_info({_pid, _events}, state) do
    {:noreply, state}
  end
end
