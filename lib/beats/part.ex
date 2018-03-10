defmodule Beats.Part do
  defstruct voice: nil, pattern: []

  def note_for(_part, _measure, sixteenth) do
    if rem(sixteenth, 4) == 0 do
      {36, 127}
    end
  end
end
