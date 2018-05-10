defmodule Beats.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :beats,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :portmidi, :ex_ncurses],
      mod: {Beats.Application, []}
    ]
  end

  defp aliases do
    [
      s: "run --no-halt -e \"\" ",
      t: "run --no-halt -e \"\" -- --filename test.json"
    ]
  end

  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:poison, "~> 3.1"},
      {:portmidi, git: "https://github.com/mtrudel/ex-portmidi"},
      {:sched_ex, "~> 1.0.0"},
      {:ex_ncurses, git: "https://github.com/mtrudel/ex_ncurses.git"},
      {:distillery, "~> 1.4", runtime: false}
    ]
  end
end
