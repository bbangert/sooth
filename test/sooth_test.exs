defmodule SoothTest do
  use ExUnit.Case
  doctest Sooth

  test "greets the world" do
    assert Sooth.hello() == :world
  end
end
