defmodule Beats.Output do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def play(notes) do
    GenServer.call(__MODULE__, {:play, notes})
  end

  # Server API

  def init(_arg) do
    {:ok, output_pid} = PortMidi.open(:output, "IAC Driver IAC Bus 1")
    {:ok, %{output_pid: output_pid}}
  end

  def handle_call({:play, notes}, _from, %{output_pid: output_pid} = state) do
    # Notes are {key, velocity} pairs and we assume them all to be 'note on'
    notes
    |> Enum.map(fn {key, velocity} -> {0b10010000, key, velocity} end)
    |> Enum.map(&PortMidi.write(output_pid, &1))

    {:reply, :ok, state}
  end
end
