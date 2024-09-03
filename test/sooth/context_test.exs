defmodule SoothContextTest do
  import Aja
  use ExUnit.Case
  use ExUnitProperties

  doctest Sooth.Context

  test "creates empty context" do
    assert match?(%Sooth.Context{id: 0, count: 0, statistics: vec([])}, Sooth.Context.new(0))
  end

  describe "find_statistic/2" do
    property "inserts unique events that are sorted" do
      check all(events <- uniq_list_of(non_negative_integer(), max_tries: 500)) do
        context =
          Enum.shuffle(events)
          |> Enum.reduce(Sooth.Context.new(0), fn event, context ->
            {context, _, _} = Sooth.Context.find_statistic(context, event)
            context
          end)

        stats = Enum.sort(events) |> Enum.map(&Sooth.Statistic.new(&1, 0))
        assert Aja.Vector.new(stats) == context.statistics
      end
    end
  end

  describe "observe/2" do
    property "increments the counts of the observed events" do
      check all(events <- list_of(non_negative_integer(), max_tries: 500)) do
        context =
          Enum.reduce(events, Sooth.Context.new(0), fn event, context ->
            {context, _} = Sooth.Context.observe(context, event)
            context
          end)

        # Build a map of event -> count
        counts =
          events
          |> Enum.reduce(%{}, fn event, acc ->
            Map.update(acc, event, 1, &(&1 + 1))
          end)

        assert context.count == length(events)

        # Verify all the statistic counts match the counts
        Enum.each(context.statistics, fn stat ->
          assert Map.get(counts, stat.event) == stat.count
        end)
      end
    end
  end
end
