defmodule Beats.MixProject do
  use Mix.Project

  def project do
    [
      app: :beats,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :portmidi],
      mod: {Beats.Application, []}
    ]
  end

  defp deps do
    [
      {:portmidi, "~> 5.0"},
      {:sched_ex, "~> 0.6.0"}
    ]
  end
end
