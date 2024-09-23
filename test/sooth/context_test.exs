defmodule SoothContextTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Sooth.Context

  test "creates empty context" do
    assert match?(
             %Sooth.Context{
               id: 0,
               count: 0,
               statistic_set: _gbset,
               statistic_objects: %{}
             },
             Sooth.Context.new(0)
           )
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
        Enum.each(Map.values(context.statistic_objects), fn stat ->
          assert Map.get(counts, stat.event) == stat.count
        end)
      end
    end
  end
end
