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
    {:ok, output_pid} = PortMidi.open(:output, "IAC Driver IAC Bus 1")
    {:ok, %{output_pid: output_pid, beat: 1}}
  end

  def handle_call(:do_beat, _from, %{output_pid: output_pid, beat: beat} = state) do
    # TODO -- farm this out to players
    PortMidi.write(output_pid, {0b10010000, 42, 127})
    {:reply, beat, %{state | beat: beat + 1}}
  end

  def handle_call({:reset_beat, to}, _from, state) do
    IO.puts "Resetting beat to #{to}"
    {:reply, to, %{state | beat: to}}
  end
end
