defmodule Beats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Parse arguments
    {opts, _, _} =
      System.argv()
      |> OptionParser.parse(switches: [filename: :string])

    # List all child processes to be supervised
    children = [
      Beats.Display,
      Beats.StatsTracker,
      Beats.Metronome,
      Beats.FileWatcher,
      Beats.Output,
      {Beats.Conductor, opts},
      Beats.Knob
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Beats.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
