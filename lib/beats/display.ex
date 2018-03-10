defmodule Beats.Display do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
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

  def set_progress(measure, quarter) do
    GenServer.cast(__MODULE__, {:set_progress, measure, quarter})
  end

  # Server API

  # Basic setup & screen maintenance

  def init(_arg) do
    GenServer.cast(__MODULE__, :setup)
    {:ok, %{}}
  end

  def terminate(:normal, _state) do
    ExNcurses.n_end()
    System.halt()
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
    ExNcurses.attron(1)
    clear_screen()
    __MODULE__.set_bpm_goal(0)
    __MODULE__.set_bpm_actual(0.0)
    __MODULE__.set_bpm_error(0.0)
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

  def handle_cast({:set_progress, measure, quarter}, state) do
    lines = ExNcurses.lines()
    ExNcurses.mvprintw(lines - 4, 2, "Measure #{measure + 1}, beat #{quarter + 1}")
    ExNcurses.refresh()
    {:noreply, state}
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
