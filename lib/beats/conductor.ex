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
    score = Beats.Score.default_score()
    {:ok, %{tick: 1, score: score}}
  end

  def handle_call(:do_tick, _from, %{score: score, tick: tick} = state) do
    # Map the tick into a musical measure and direct everyone to play it
    measure = div(tick, 16)
    sixteenth = rem(tick, 16)

    # Collect all the notes to play from the current score and play them
    score.parts
    |> Enum.map(&Beats.Part.note_for(&1, measure, sixteenth))
    |> Enum.filter(& &1)
    |> Beats.Output.play()

    if rem(sixteenth, 4) == 0 do
      Beats.Display.set_progress(measure, div(sixteenth, 4))
    end

    {:reply, tick, %{state | tick: tick + 1}}
  end

  def handle_call({:reset_tick, to}, _from, state) do
    Beats.Display.puts("Resetting tick to #{to}")
    {:reply, to, %{state | tick: to}}
  end
end
