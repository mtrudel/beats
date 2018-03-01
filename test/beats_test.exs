defmodule BeatsTest do
  use ExUnit.Case
  doctest Beats

  test "greets the world" do
    assert Beats.hello() == :world
  end
end
