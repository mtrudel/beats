defmodule Beats.Display do
  use GenServer

  # Client API

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def set_bpm_actual(bpm) do
    GenServer.cast(__MODULE__, {:set_bpm_actual, bpm})
  end

  def set_bpm_goal(bpm) do
    GenServer.cast(__MODULE__, {:set_bpm_goal, bpm})
  end

  def set_bpm_error(error) do
    GenServer.cast(__MODULE__, {:set_bpm_error, error})
  end

  # Server API
  
  # Basic setup & screen maintenance
  
  def init(_arg) do 
    GenServer.cast(__MODULE__, :setup)
    {:ok, %{bpm_actual: 0.0, bpm_goal: 0.0, bpm_error: 0.0}}
  end

  def terminate(:normal, _state) do
    ExNcurses.n_end()
    System.halt
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
    repaint_bpm(state)
    {:noreply, state}
  end

  # BPM display

  def handle_cast({:set_bpm_actual, bpm}, state) do
    state = %{state | bpm_actual: bpm}
    repaint_bpm(state)
    {:noreply, state}
  end

  def handle_cast({:set_bpm_goal, bpm}, state) do
    state = %{state | bpm_goal: bpm}
    repaint_bpm(state)
    {:noreply, state}
  end

  def handle_cast({:set_bpm_error, error}, state) do
    state = %{state | bpm_error: error}
    repaint_bpm(state)
    {:noreply, state}
  end

  defp repaint_bpm(state) do
    ExNcurses.mvprintw(2, 2, "Target BPM: #{state.bpm_goal}   ")
    ExNcurses.mvprintw(3, 2, "Actual BPM: #{Float.round(state.bpm_actual, 2)}   ")
    ExNcurses.mvprintw(4, 2, "     Error: #{abs(Float.round(state.bpm_error, 2))}%%   ")
    ExNcurses.refresh()
  end

  # Background 

  defp clear_screen do
    lines = ExNcurses.lines()
    cols = ExNcurses.cols()
    for line <- 0..lines, col <- 0..cols do
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
