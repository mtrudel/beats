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
    Beats.FileWatcher.subscribe()
    score = Beats.Score.default_score()
    Beats.Metronome.set_bpm(score.desired_bpm)
    Beats.Metronome.toggle()
    {:ok, %{tick: 1, score: score, pending_score: nil}}
  end

  def handle_call(:do_tick, _from, %{score: score, pending_score: pending_score, tick: tick} = state) do
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

    if (sixteenth == 15 && pending_score) do
      Beats.Metronome.set_bpm(pending_score.desired_bpm)
      {:reply, tick, %{tick: tick + 1, score: pending_score, pending_score: nil}}
    else
      {:reply, tick, %{state | tick: tick + 1}}
    end
  end

  def handle_call({:reset_tick, to}, _from, state) do
    Beats.Display.puts("Resetting tick to #{to}")
    {:reply, to, %{state | tick: to}}
  end

  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    if String.ends_with?(path, ".json") do
      score = Beats.Score.score_from_file(path)
      {:noreply, %{state | pending_score: score}}
    else
      {:noreply, state}
    end
  end
end
