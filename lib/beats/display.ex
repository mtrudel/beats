defmodule Beats.Display do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def kill_display do
    GenServer.stop(__MODULE__)
  end

  def puts(string) do
    GenServer.cast(__MODULE__, {:puts, string})
  end

  def set_bpm_goal(bpm) do
    GenServer.cast(__MODULE__, {:set_bpm_goal, bpm})
  end

  def set_bpm_actual(bpm) do
    GenServer.cast(__MODULE__, {:set_bpm_actual, bpm})
  end

  def set_bpm_error(error) do
    GenServer.cast(__MODULE__, {:set_bpm_error, error})
  end

  def set_playing(playing) do
    GenServer.cast(__MODULE__, {:set_playing, playing})
  end

  def set_progress(measure, quarter) do
    GenServer.call(__MODULE__, {:set_progress, measure, quarter})
  end

  def draw_beat(beat, highlighted) do
    GenServer.call(__MODULE__, {:draw_beat, beat, highlighted})
  end

  def set_score(score) do
    GenServer.cast(__MODULE__, {:set_score, score})
  end

  # Server API

  # Basic setup & screen maintenance

  def init(_arg) do
    GenServer.cast(__MODULE__, :setup)
    {:ok, %{pattern: []}}
  end

  def terminate(_reason, _state) do
    ExNcurses.n_end()
  end

  def handle_cast(:setup, state) do
    ExNcurses.n_begin()
    ExNcurses.noecho()
    ExNcurses.start_color()
    ExNcurses.init_pair(1, ExNcurses.clr(:WHITE), ExNcurses.clr(:CYAN))
    ExNcurses.init_pair(2, ExNcurses.clr(:MAGENTA), ExNcurses.clr(:CYAN))
    ExNcurses.init_pair(3, ExNcurses.clr(:YELLOW), ExNcurses.clr(:BLACK))
    ExNcurses.init_pair(4, ExNcurses.clr(:MAGENTA), ExNcurses.clr(:WHITE))
    ExNcurses.attron(1)
    clear_screen()
    __MODULE__.set_bpm_goal(0)
    __MODULE__.set_bpm_actual(0.0)
    __MODULE__.set_bpm_error(0.0)
    __MODULE__.set_playing(false)
    SchedEx.run_in(__MODULE__, :handle_input, [], 50, repeat: true)
    __MODULE__.puts("Setup Complete")
    {:noreply, state}
  end

  # Console

  def handle_cast({:puts, string}, state) do
    lines = ExNcurses.lines()
    ExNcurses.mvprintw(lines - 2, 2, "                        ")
    ExNcurses.mvprintw(lines - 2, 2, string || "")
    ExNcurses.refresh()
    {:noreply, state}
  end

  # Note display

  def handle_cast({:set_playing, playing}, state) do
    lines = ExNcurses.lines()
    message = if playing, do: "PLAYING", else: "STOPPED"
    ExNcurses.mvprintw(lines - 4, 2, message)
    ExNcurses.refresh()
    {:noreply, state}
  end

  def handle_call({:set_progress, measure, quarter}, _from, state) do
    lines = ExNcurses.lines()
    ExNcurses.mvprintw(lines - 4, 10, "Measure #{measure + 1}, beat #{quarter + 1}")
    ExNcurses.refresh()
    {:reply, :ok, state}
  end

  # BPM display

  def handle_cast({:set_bpm_goal, bpm_goal}, state) do
    ExNcurses.mvprintw(2, 2, "Target BPM: #{bpm_goal}   ")
    ExNcurses.refresh()
    {:noreply, state}
  end

  def handle_cast({:set_bpm_actual, bpm_actual}, state) do
    ExNcurses.mvprintw(3, 2, "Actual BPM: #{Float.round(bpm_actual, 2)}   ")
    ExNcurses.refresh()
    {:noreply, state}
  end

  def handle_cast({:set_bpm_error, error}, state) do
    ExNcurses.mvprintw(4, 2, "     Error: #{abs(Float.round(error, 2))}%%   ")
    ExNcurses.refresh()
    {:noreply, state}
  end

  # Score display
  
  def handle_cast({:set_score, %Beats.Score{parts: parts}}, state) do
    for line <- 9..(12 * 3),
        col <- 2..(6 + (32 * 4)) do
      ExNcurses.mvprintw(line, col, " ")
    end

    parts
    |> Enum.with_index()
    |> Enum.each(fn({%Beats.Part{name: name}, index}) -> 
      ExNcurses.attron(1)
      ExNcurses.mvprintw(9 + (3 * index), 3, name)
    end)
    ExNcurses.attron(1)
    ExNcurses.refresh()

    longest_pattern = parts
                      |> Enum.map(&(length(&1.pattern)))
                      |> Enum.max()

    pattern = 0..(longest_pattern - 1)
              |> Enum.map(fn(column) ->
                parts
                |> Enum.map(fn(%Beats.Part{pattern: pattern}) -> 
                  case Enum.at(pattern, rem(column, length(pattern))) do
                    0 -> " "
                    1 -> "x"
                    2 -> "X"
                  end
                end)
              end)

    for column <- 0..(longest_pattern - 1) do
      handle_call({:draw_beat, column, false}, nil, %{pattern: pattern})
    end

    {:noreply, %{state | pattern: pattern}}
  end

  def handle_call({:draw_beat, beat, highlighted}, _from, %{pattern: pattern} = state) do
    if highlighted do
      ExNcurses.attron(4)
    else
      ExNcurses.attron(3)
    end

    column = rem(beat, length(pattern))
    pattern
    |> Enum.at(column)
    |> Enum.with_index()
    |> Enum.each(fn({to_draw, index}) -> 
      ExNcurses.mvprintw(9 + (3 * index), 6 + (4 * column), "#{to_draw}#{to_draw}#{to_draw}")
      ExNcurses.mvprintw(10 + (3 * index), 6 + (4 * column), "#{to_draw}#{to_draw}#{to_draw}")
    end)
    ExNcurses.attron(1)
    ExNcurses.refresh()
    {:reply, :ok, state}
  end

  # Input

  def handle_input do
    case ExNcurses.getch() do
      -1 -> nil
      ch -> case List.to_string([ch]) do
        "1" -> Beats.Conductor.play_fill(1)
        "2" -> Beats.Conductor.play_fill(2)
        "3" -> Beats.Conductor.play_fill(3)
        "4" -> Beats.Conductor.play_fill(4)
        "u" -> Beats.Metronome.speed_up()
        "d" -> Beats.Metronome.slow_down()
        " " -> Beats.Metronome.toggle()
        "r" -> kill_display()
        "q" -> System.halt()
        _ -> nil
      end
    end
  end

  # Background 

  defp clear_screen do
    lines = ExNcurses.lines()
    cols = ExNcurses.cols()

    for line <- 0..lines,
        col <- 0..cols do
      ExNcurses.mvprintw(line, col, " ")
    end

    ExNcurses.attron(2)
    ExNcurses.mvprintw(1, cols - 38, ~S( ___.                  __           ))
    ExNcurses.mvprintw(2, cols - 38, ~S( \_ |__   ____ _____ _/  |_  ______ ))
    ExNcurses.mvprintw(3, cols - 38, ~S(  | __ \_/ __ \\__  \\   __\/  ___/ ))
    ExNcurses.mvprintw(4, cols - 38, ~S(  | \_\ \  ___/ / __ \|  |  \___ \  ))
    ExNcurses.mvprintw(5, cols - 38, ~S(  |___  /\___  >____  /__| /____  > ))
    ExNcurses.mvprintw(6, cols - 38, ~S(      \/     \/     \/          \/  ))
    ExNcurses.attron(1)
  end
end
