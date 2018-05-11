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

  def play_fill(num) do
    GenServer.call(__MODULE__, {:play_fill, num})
  end

  def toggle_update_display do
    GenServer.call(__MODULE__, :toggle_update_display)
  end

  # Server API

  def init(arg) do
    Beats.FileWatcher.subscribe()

    score =
      arg
      |> Keyword.get(:filename, "default.json")
      |> Beats.Score.score_from_file()
      |> load_score()

    {:ok,
     %{
       tick: 0,
       score: score,
       current_score: score,
       pending_score: nil,
       pending_fill: nil,
       update_display: true
     }}
  end

  def handle_call(
        :do_tick,
        _from,
        %{
          score: score,
          current_score: %Beats.Score{channel: channel} = current_score,
          pending_score: pending_score,
          pending_fill: pending_fill,
          update_display: update_display,
          tick: tick
        } = state
      ) do
    # Map the tick into a musical measure and direct everyone to play it
    measure = div(tick, 16)
    sixteenth = rem(tick, 16)

    # Collect all the notes to play from the current score and play them
    score.parts
    |> Enum.map(&Beats.Part.note_for(&1, measure, sixteenth))
    |> Enum.filter(& &1)
    |> Beats.Output.play(channel)

    if (update_display) do
      # Update the display
      Beats.Display.set_tick(tick)
    end

    # Update our state according to whether we're at the end of a measure or not
    cond do
      sixteenth == 15 && pending_score ->
        # New score coming our way
        load_score(pending_score)

        {:reply, tick,
         %{
           tick: 0,
           score: pending_score,
           current_score: pending_score,
           pending_score: nil,
           pending_fill: nil
         }}

      sixteenth == 15 && pending_fill ->
        # Fill request enqueued
        Beats.Display.set_score(pending_fill)

        {:reply, tick,
         %{
           tick: tick + 1,
           score: pending_fill,
           current_score: current_score,
           pending_score: nil,
           pending_fill: nil
         }}

      sixteenth == 15 && score != current_score ->
        # Restoring after a fill
        Beats.Display.set_score(current_score)

        {:reply, tick,
         %{
           tick: tick + 1,
           score: current_score,
           current_score: current_score,
           pending_score: nil,
           pending_fill: nil
         }}

      true ->
        {:reply, tick, %{state | tick: tick + 1}}
    end
  end

  def handle_call({:reset_tick, to}, _from, state) do
    Beats.Display.puts("Resetting tick to #{to}")
    {:reply, to, %{state | tick: to}}
  end

  def handle_call({:play_fill, num}, _from, %{current_score: %{fills: fills}} = state) do
    if length(fills) >= num do
      Beats.Display.puts("Playing fill #{num}")
      {:reply, :ok, %{state | pending_fill: Enum.at(fills, num - 1)}}
    else
      Beats.Display.puts("Fill #{num} not defined")
      {:reply, :no_such_fill, state}
    end
  end

  def handle_call(:toggle_update_display, _from, %{update_display: update_display} = state) do
    Beats.Display.puts("Updating Display: #{!update_display}")
    {:reply, :ok, %{state | update_display: !update_display}}
  end

  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    if String.ends_with?(path, ".json") do
      case Beats.Score.score_from_file(path) do
        %Beats.Score{} = score ->
          {:noreply, %{state | pending_score: score}}

        _ ->
          Beats.Display.puts("Could not parse #{Path.basename(path)}")
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  defp load_score(score) do
    Beats.Display.set_score(score)
    Beats.Metronome.set_bpm(score.desired_bpm)
    Beats.Metronome.set_swing(score.swing)
    score
  end
end
