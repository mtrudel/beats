defmodule Beats.Conductor do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def do_beat() do
    GenServer.call(__MODULE__, :do_beat)
  end

  def reset_beat(to \\ 1) do
    GenServer.call(__MODULE__, {:reset_beat, to})
  end

  # Server API
  
  def init(_arg) do 
    {:ok, %{beat: 1}}
  end

  def handle_call(:do_beat, _from, %{beat: beat} = state) do
    # TODO fan this out to MIDI, and eventually to multiple channels based on a score
    System.cmd("/usr/bin/afplay", ["/System/Library/Sounds/Funk.aiff"])
    {:reply, beat, %{state | beat: beat + 1}}
  end

  def handle_call({:reset_beat, to}, _from, state) do
    IO.puts "Resetting beat to #{to}"
    {:reply, to, %{state | beat: to}}
  end
end
