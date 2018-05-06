defmodule Beats.Score do
  defstruct name: nil, desired_bpm: 120, swing: 0.5, channel: 1, parts: [], fills: []

  def score_from_file(filename) do
    filename =
      if Path.basename(filename) == filename do
        Path.join(Application.get_env(:beats, :score_dir), filename)
      else
        filename
      end

    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Poison.decode(body) do
      from_json(json)
    end
  end

  def from_json(json) do
    %__MODULE__{
      name: Map.get(json, "name"),
      desired_bpm: Map.get(json, "bpm"),
      swing: Map.get(json, "swing", 0.5),
      channel: Map.get(json, "channel", 1),
      parts: Map.get(json, "parts") |> Enum.map(&Beats.Part.from_json/1),
      fills: Map.get(json, "fills", []) |> Enum.map(&Beats.Score.from_json/1)
    }
  end
end
