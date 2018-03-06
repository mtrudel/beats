defmodule Beats.Conductor do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_tick() do
    GenServer.call(__MODULE__, :do_tick)
  end

  def reset_tick(to \\ 1) do
    GenServer.call(__MODULE__, {:reset_tick, to})
  end

  # Server API
  
  def init(_arg) do 
    {:ok, output_pid} = PortMidi.open(:output, "IAC Driver IAC Bus 1")
    {:ok, %{output_pid: output_pid, tick: 1}}
  end

  def handle_call(:do_tick, _from, %{output_pid: output_pid, tick: tick} = state) do
    note = div(tick, 4)
    measure = rem(div(note, 4), 4)
    beat = rem(note, 4)

    to_play = case measure do
      0 -> regular_measure(tick)
      1 -> regular_measure(tick)
      2 -> regular_measure(tick)
      3 -> accent_measure(tick)
    end

    for note <- to_play do
      PortMidi.write output_pid, {0b10010000, note, 127}
    end

    {:reply, tick, %{state | tick: tick + 1}}
  end

  def handle_call({:reset_tick, to}, _from, state) do
    IO.puts "Resetting tick to #{to}"
    {:reply, to, %{state | tick: to}}
  end

  @bd 36
  @sd 38
  @lt 45
  @md 47
  @ht 50
  @rs 37
  @cp 39
  @cb 56 
  @cy 49
  @oh 46
  @ch 42
  @lc 61
  @mc 62
  @hc 63
  @cl 75
  @ma 70

  defp regular_measure(note) do
    case rem(note, 16) do
      0  -> [@ch, @bd]
      1  -> []
      2  -> [@ch]
      3  -> []
      4  -> [@ch, @sd]
      5  -> []
      6  -> [@ch]
      7  -> []
      8  -> [@ch]
      9  -> []
      10 -> [@ch, @bd]
      11 -> []
      12 -> [@ch, @sd]
      13 -> []
      14 -> [@ch]
      15 -> []
    end
  end

  defp accent_measure(note) do
    case rem(note, 16) do
      0  -> [@ch, @bd]
      1  -> []
      2  -> [@ch]
      3  -> []
      4  -> [@ch, @sd]
      5  -> []
      6  -> [@ch, @cb]
      7  -> []
      8  -> [@ch]
      9  -> []
      10 -> [@ch, @bd]
      11 -> []
      12 -> [@ch, @cb]
      13 -> []
      14 -> [@ch, @sd]
      15 -> []
    end
  end


end
