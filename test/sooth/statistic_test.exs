defmodule SoothStatisticTest do
  use ExUnit.Case
  doctest Sooth.Statistic

  test "creates empty statistic" do
    assert match?(%Sooth.Statistic{event: 0, count: 0}, Sooth.Statistic.new(0, 0))
  end
end
