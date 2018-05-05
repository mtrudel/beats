defmodule Beats.Display do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def puts(string) do
    GenServer.call(__MODULE__, {:puts, string})
  end

  def set_bpm_goal(bpm) do
    GenServer.call(__MODULE__, {:set_bpm_goal, bpm})
  end

  def set_bpm_actual(bpm) do
    GenServer.call(__MODULE__, {:set_bpm_actual, bpm})
  end

  def set_bpm_error(error) do
    GenServer.call(__MODULE__, {:set_bpm_error, error})
  end

  def set_swing(swing) do
    GenServer.call(__MODULE__, {:set_swing, swing})
  end

  def set_playing(playing) do
    GenServer.call(__MODULE__, {:set_playing, playing})
  end

  def set_tick(tick) do
    GenServer.call(__MODULE__, {:set_tick, tick})
  end

  def set_score(score) do
    GenServer.call(__MODULE__, {:set_score, score})
  end

  def toggle_stats do
    GenServer.call(__MODULE__, :toggle_stats)
  end

  def update_stats(stats) do
    GenServer.call(__MODULE__, {:update_stats, stats})
  end

  # Server API

  # Basic setup & screen maintenance

  def init(_arg) do
    GenServer.cast(__MODULE__, :setup)
    SchedEx.run_in(__MODULE__, :handle_input, [], 50, repeat: true)

    {:ok,
     %{
       bpm_goal: 0,
       bpm_actual: 0.0,
       bpm_error: 0.0,
       swing: 0.5,
       tick: 0,
       playing: false,
       console: nil,
       score: %Beats.Score{},
       stats_type: :scheduling_delay,
       pattern: [[]]
     }}
  end

  def handle_cast(:setup, state) do
    initialize_curses()
    clear_screen()
    display_bpm_goal(state.bpm_goal)
    display_bpm_actual(state.bpm_actual)
    display_bpm_error(state.bpm_error)
    display_swing(state.swing)
    display_name(state.score.name)
    display_grid(state.score, state.pattern)
    display_progress(state.tick)
    display_playing(state.playing)
    display_console(state.console)
    {:noreply, state}
  end

  # BPM display

  def handle_call({:set_bpm_goal, bpm_goal}, _from, state) do
    display_bpm_goal(bpm_goal)
    {:reply, :ok, %{state | bpm_goal: bpm_goal}}
  end

  def handle_call({:set_bpm_actual, bpm_actual}, _from, state) do
    display_bpm_actual(bpm_actual)
    {:reply, :ok, %{state | bpm_actual: bpm_actual}}
  end

  def handle_call({:set_bpm_error, error}, _from, state) do
    display_bpm_error(error)
    {:reply, :ok, %{state | bpm_error: error}}
  end

  def handle_call({:set_swing, swing}, _from, state) do
    display_swing(swing)
    {:reply, :ok, %{state | swing: swing}}
  end

  # Status display

  def handle_call({:set_tick, tick}, _from, %{pattern: pattern} = state) do
    display_progress(tick)
    display_grid_column(tick - 1, pattern, false)
    display_grid_column(tick, pattern, true)
    {:reply, :ok, %{state | tick: tick}}
  end

  def handle_call({:set_playing, playing}, _from, state) do
    display_playing(playing)
    {:reply, :ok, %{state | playing: playing}}
  end

  # Console

  def handle_call({:puts, string}, _from, state) do
    display_console(string)
    {:reply, :ok, %{state | console: string}}
  end

  # Score display

  def handle_call({:set_score, %Beats.Score{name: name} = score}, _from, state) do
    display_name(name)
    pattern = pattern_from_score(score)
    display_grid(score, pattern)
    {:reply, :ok, %{state | score: score, pattern: pattern}}
  end

  # Stats display

  def handle_call(
        {:update_stats, %SchedEx.Stats{} = stats},
        _from,
        %{stats_type: stats_type} = state
      ) do
    %SchedEx.Stats.Value{
      min: min,
      max: max,
      avg: avg,
      count: count,
      histogram: histogram
    } = Map.get(stats, stats_type)

    display_stats(stats_type, min, max, avg, count, histogram)
    {:reply, :ok, state}
  end

  def handle_call(:toggle_stats, _from, %{stats_type: stats_type} = state) do
    new_stats_type = case stats_type do
      :scheduling_delay -> :quantization_error
      :quantization_error -> :scheduling_delay
    end
    {:reply, :ok, %{state | stats_type: new_stats_type}}
  end

  # Curses lifecycle

  defp initialize_curses do
    ExNcurses.n_begin()
    ExNcurses.noecho()
    ExNcurses.start_color()
    ExNcurses.init_pair(1, :white, :cyan)
    ExNcurses.init_pair(2, :magenta, :cyan)
    ExNcurses.init_pair(3, :white, :black)
    ExNcurses.init_pair(4, :white, :red)
    ExNcurses.init_pair(5, :white, :blue)
    ExNcurses.init_pair(6, :black, :white)
    ExNcurses.init_pair(7, :red, :cyan)
    ExNcurses.attron(1)
  end

  defp shutdown_curses do
    ExNcurses.n_end()
  end

  # Display methods

  defp display_bpm_goal(bpm_goal) do
    ExNcurses.mvprintw(1, 4, "Target BPM: #{bpm_goal}   ")
    ExNcurses.refresh()
  end

  defp display_bpm_actual(bpm_actual) do
    ms_per_16th = if bpm_actual != 0, do: trunc(1000 / (bpm_actual / 60)), else: 0
    ExNcurses.mvprintw(2, 4, "Actual BPM: #{Float.round(bpm_actual, 2)} (#{ms_per_16th}ms)   ")
    ExNcurses.refresh()
  end

  defp display_bpm_error(error) do
    ExNcurses.mvprintw(3, 4, "     Error: #{abs(Float.round(error, 2))}%   ")
    ExNcurses.refresh()
  end

  defp display_swing(swing) do
    ExNcurses.mvprintw(4, 4, "     Swing: #{round(100 * swing)}%   ")
    ExNcurses.refresh()
  end

  defp display_progress(tick) do
    if rem(tick, 4) == 0 do
      measure = div(tick, 16)
      beat = div(rem(tick, 16), 4)
      lines = ExNcurses.lines()
      ExNcurses.mvprintw(lines - 4, 10, "Measure #{measure + 1}, Beat #{beat + 1}    ")
      ExNcurses.refresh()
    end
  end

  defp display_playing(playing) do
    lines = ExNcurses.lines()
    message = if playing, do: "PLAYING", else: "STOPPED"
    ExNcurses.mvprintw(lines - 4, 2, message)
    ExNcurses.refresh()
  end

  defp display_console(string) do
    lines = ExNcurses.lines()
    ExNcurses.mvprintw(lines - 2, 2, "                        ")
    ExNcurses.mvprintw(lines - 2, 2, string || "")
    ExNcurses.refresh()
  end

  defp display_name(name) do
    aesthetic_name = (name || "") 
                     |> String.upcase()
                     |> String.graphemes() 
                     |> Enum.intersperse(" ") 
                     |> Enum.join()
    x = round((ExNcurses.cols() - String.length(aesthetic_name)) / 2)
    ExNcurses.mvprintw(3, round(ExNcurses.cols() / 2) - 15, "                              ")
    ExNcurses.mvprintw(3, x, aesthetic_name)
    ExNcurses.refresh()
  end

  defp display_grid(%Beats.Score{parts: parts}, pattern) do
    # Clear the ground
    for line <- 7..(ExNcurses.lines() - 6), col <- 2..(ExNcurses.cols() - 36) do
      ExNcurses.mvprintw(line, col, " ")
    end

    parts
    |> Enum.with_index()
    |> Enum.each(fn {%Beats.Part{name: name}, index} ->
      ExNcurses.attron(1)
      ExNcurses.mvprintw(7 + 2 * index, 3, name)
    end)

    ExNcurses.attron(1)
    ExNcurses.refresh()

    for {_, column} <- Enum.with_index(pattern) do
      display_grid_column(column, pattern, false)
    end
  end

  defp display_grid_column(column, pattern, highlighted) do
    column = rem(length(pattern) + column, length(pattern))
    column_width = (ExNcurses.cols() - 44) / length(pattern)
                   |> trunc()
                   |> max(2)
                   |> min(4)

    pattern
    |> Enum.at(column)
    |> Enum.with_index()
    |> Enum.each(fn {to_draw, index} ->
      cond do
        to_draw != 0 && highlighted -> ExNcurses.attron(4)
        to_draw != 0 -> ExNcurses.attron(5)
        true -> ExNcurses.attron(3)
      end

      ExNcurses.mvprintw(7 + 2 * index, 6 + column_width * column, String.duplicate(" ", column_width - 1))
    end)

    ExNcurses.attron(1)
    ExNcurses.refresh()
  end

  defp display_stats(type, min, max, avg, count, histogram) do
    lines = ExNcurses.lines()
    cols = ExNcurses.cols()
    ExNcurses.attron(:bold)
    ExNcurses.attron(2)
    ExNcurses.mvprintw(lines - 20, cols - 27, "Sched")
    ExNcurses.attron(7)
    ExNcurses.mvprintw(lines - 20, cols - 22, "Ex")
    ExNcurses.attron(1)
    ExNcurses.mvprintw(lines - 20, cols - 19, "Stats")
    ExNcurses.attroff(:bold)

    type_string = case type do
      :scheduling_delay -> "Scheduling Delay  "
      :quantization_error -> "Quantization Error"
    end
    ExNcurses.mvprintw(lines - 18, cols - 36, type_string)

    histogram
    |> Enum.take(16)
    |> Enum.with_index()
    |> Enum.each(fn {bucket, x} ->
      height = round(10 * (bucket / count))
      for y <- 0..9 do
        if y < height, do: ExNcurses.attron(6), else: ExNcurses.attron(3)
        ExNcurses.mvprintw(lines - 8 - y, cols - 36 + (2 * x), "  ")
      end
    end)

    ExNcurses.attron(1)
    ExNcurses.mvprintw(lines - 7, cols - 36, "0us                       1500us")
    ExNcurses.mvprintw(lines - 5, cols - 28, "  Min: #{min}us     ")
    ExNcurses.mvprintw(lines - 4, cols - 28, "  Max: #{max}us     ")
    ExNcurses.mvprintw(lines - 3, cols - 28, "  Avg: #{trunc(avg)}us     ")
    ExNcurses.mvprintw(lines - 2, cols - 28, "Calls: #{count}     ")
    ExNcurses.refresh()
  end

  defp clear_screen do
    lines = ExNcurses.lines()
    cols = ExNcurses.cols()

    for line <- 0..lines,
        col <- 0..cols do
      ExNcurses.mvprintw(line, col, " ")
    end

    ExNcurses.attron(:bold)
    ExNcurses.attron(7)
    ExNcurses.mvprintw(1, cols - 38, ~S( ___.                  __           ))
    ExNcurses.mvprintw(2, cols - 38, ~S( \_ |__   ____ _____ _/  |_  ______ ))
    ExNcurses.mvprintw(3, cols - 38, ~S(  | __ \_/ __ \\__  \\   __\/  ___/ ))
    ExNcurses.mvprintw(4, cols - 38, ~S(  | \_\ \  ___/ / __ \|  |  \___ \  ))
    ExNcurses.mvprintw(5, cols - 38, ~S(  |___  /\___  >____  /__| /____  > ))
    ExNcurses.mvprintw(6, cols - 38, ~S(      \/     \/     \/          \/  ))
    ExNcurses.attroff(:bold)
    ExNcurses.attron(1)
  end

  # Input

  def handle_input do
    case ExNcurses.getch() do
      -1 ->
        nil

      ch ->
        case List.to_string([ch]) do
          "1" -> Beats.Conductor.play_fill(1)
          "2" -> Beats.Conductor.play_fill(2)
          "3" -> Beats.Conductor.play_fill(3)
          "4" -> Beats.Conductor.play_fill(4)
          "5" -> Beats.Conductor.play_fill(5)
          "6" -> Beats.Conductor.play_fill(6)
          "7" -> Beats.Conductor.play_fill(7)
          "8" -> Beats.Conductor.play_fill(8)
          "9" -> Beats.Conductor.play_fill(9)
          "0" -> Beats.Conductor.play_fill(10)
          "u" -> Beats.Metronome.speed_up()
          "d" -> Beats.Metronome.slow_down()
          " " -> Beats.Metronome.toggle()
          "w" -> Beats.Metronome.swing_less()
          "e" -> Beats.Metronome.swing_more()
          "s" -> toggle_stats()
          "r" -> rebuild_display()
          "q" -> System.halt()
          _ -> nil
        end
    end
  end

  defp rebuild_display do
    shutdown_curses()
    GenServer.cast(__MODULE__, :setup)
  end

  # Pattern / Score helpers

  defp pattern_from_score(%Beats.Score{parts: parts}) do
    longest_pattern =
      parts
      |> Enum.map(&length(&1.pattern))
      |> Enum.max()

    0..(longest_pattern - 1)
    |> Enum.map(fn column ->
      parts
      |> Enum.map(fn %Beats.Part{pattern: pattern} ->
        Enum.at(pattern, rem(column, length(pattern)))
      end)
    end)
  end
end
