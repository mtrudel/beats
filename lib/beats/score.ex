defmodule Beats.Score do
  defstruct name: nil, desired_bpm: 120, swing: 0.5, parts: [], fills: []

  def default_score do
    score_from_file("/Users/mat/Code/beats/scores/default.json")
  end

  def score_from_file(filename) do
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
      parts: Map.get(json, "parts") |> Enum.map(&Beats.Part.from_json/1),
      fills: Map.get(json, "fills", []) |> Enum.map(&Beats.Score.from_json/1)
    }
  end
end
