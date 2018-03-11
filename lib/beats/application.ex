defmodule Beats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Beats.Metronome,
      Beats.FileWatcher,
      Beats.Output,
      Beats.Conductor,
      Beats.Knob
    ]

    children = if IEx.started?, do: children, else: [Beats.Display] ++ children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Beats.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
