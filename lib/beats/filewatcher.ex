defmodule Beats.FileWatcher do
  def start_link(_) do
    score_dir = Application.get_env(:beats, :score_dir)
    FileSystem.start_link(dirs: [score_dir], name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def subscribe do
    FileSystem.subscribe(__MODULE__)
  end
end
