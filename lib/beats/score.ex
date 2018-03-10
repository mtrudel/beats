defmodule Beats.Score do
  defstruct parts: [Beats.Part]

  def default_score do
    %__MODULE__{parts: [
      %Beats.Part{}
    ]}
  end
end
