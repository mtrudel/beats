defmodule Beats.Score do
  defstruct name: nil, parts: [Beats.Part]

  def default_score do
    score_from_file("/Users/mat/Code/beats/scores/default.json")
  end

  def score_from_file(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Poison.decode(body) do
      %__MODULE__{
        name: Map.get(json, "name"),
        parts: Map.get(json, "parts") |> Enum.map(&Beats.Part.from_json/1)
      }
    end
  end
end
