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

  def set_playing(playing) do
    GenServer.call(__MODULE__, {:set_playing, playing})
  end

  def set_tick(tick) do
    GenServer.call(__MODULE__, {:set_tick, tick})
  end

  def set_score(score) do
    GenServer.call(__MODULE__, {:set_score, score})
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
       tick: 0,
       playing: false,
       console: nil,
       score: %Beats.Score{},
       pattern: [[]]
     }}
  end

  def handle_cast(:setup, state) do
    initialize_curses()
    clear_screen()
    display_bpm_goal(state.bpm_goal)
    display_bpm_actual(state.bpm_actual)
    display_bpm_error(state.bpm_error)
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

  def handle_call({:set_score, %Beats.Score{} = score}, _from, state) do
    pattern = pattern_from_score(score)
    display_grid(score, pattern)
    {:reply, :ok, %{state | score: score, pattern: pattern}}
  end

  # Stats display

  def handle_call(
        {:update_stats,
         %SchedEx.Stats{
           scheduling_delay: %SchedEx.Stats.Value{
             min: min,
             max: max,
             avg: avg,
             count: count,
             histogram: histogram
           }
         }},
        _from,
        state
      ) do
    display_stats(min, max, avg, count, histogram)
    {:reply, :ok, state}
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
    ExNcurses.mvprintw(2, 2, "Target BPM: #{bpm_goal}   ")
    ExNcurses.refresh()
  end

  defp display_bpm_actual(bpm_actual) do
    ExNcurses.mvprintw(3, 2, "Actual BPM: #{Float.round(bpm_actual, 2)}   ")
    ExNcurses.refresh()
  end

  defp display_bpm_error(error) do
    ExNcurses.mvprintw(4, 2, "     Error: #{abs(Float.round(error, 2))}%%   ")
    ExNcurses.refresh()
  end

  defp display_progress(tick) do
    if rem(tick, 4) == 0 do
      measure = div(tick, 16)
      beat = div(rem(tick, 16), 4)
      lines = ExNcurses.lines()
      ExNcurses.mvprintw(lines - 4, 10, "Measure #{measure + 1}, beat #{beat + 1}")
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

  defp display_stats(min, max, avg, count, histogram) do
    lines = ExNcurses.lines()
    cols = ExNcurses.cols()
    ExNcurses.attron(:bold)
    ExNcurses.attron(2)
    ExNcurses.mvprintw(lines - 19, cols - 22, "Sched")
    ExNcurses.attron(7)
    ExNcurses.mvprintw(lines - 19, cols - 17, "Ex")
    ExNcurses.attron(1)
    ExNcurses.mvprintw(lines - 19, cols - 14, "Stats")
    ExNcurses.attroff(:bold)

    histogram
    |> Enum.with_index()
    |> Enum.each(fn {bucket, x} ->
      height = round(10 * (bucket / count))
      for y <- 0..9 do
        if y < height, do: ExNcurses.attron(6), else: ExNcurses.attron(3)
        ExNcurses.mvprintw(lines - 8 - y, cols - 25 + (2 * x), "  ")
      end
    end)

    ExNcurses.attron(1)
    ExNcurses.mvprintw(lines - 7, cols - 25, "0us           1000us")
    ExNcurses.mvprintw(lines - 5, cols - 20, "Min: #{min}us     ")
    ExNcurses.mvprintw(lines - 4, cols - 20, "Max: #{max}us     ")
    ExNcurses.mvprintw(lines - 3, cols - 20, "Avg: #{trunc(avg)}us     ")
    ExNcurses.mvprintw(lines - 2, cols - 22, "Calls: #{count}     ")
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
          "u" -> Beats.Metronome.speed_up()
          "d" -> Beats.Metronome.slow_down()
          " " -> Beats.Metronome.toggle()
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
