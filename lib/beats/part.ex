defmodule Beats.Part do
  defstruct name: nil, voice: nil, pattern: []

  def note_for(%__MODULE__{voice: voice, pattern: pattern}, measure, sixteenth) do
    index = rem(measure * 16 + sixteenth, length(pattern))

    case Enum.at(pattern, index) do
      0 -> nil
      1 -> {voice, 64}
      2 -> {voice, 127}
    end
  end

  def from_json(json) do
    %__MODULE__{
      name: Map.get(json, "name"),
      voice: Map.get(json, "voice"),
      pattern: Map.get(json, "pattern") |> pattern_from_string()
    }
  end

  defp pattern_from_string(string) do
    string
    |> String.graphemes()
    |> Enum.map(fn ch ->
      case ch do
        " " -> 0
        "x" -> 1
        "X" -> 2
      end
    end)
  end
end
