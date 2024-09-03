defmodule SoothPredictorTest do
  alias Sooth.Predictor
  import Aja
  use ExUnit.Case
  use ExUnitProperties

  doctest Sooth.Predictor

  test "creates empty predictor" do
    assert match?(%Predictor{error_event: 0, contexts: vec([])}, Predictor.new(0))
  end

  describe "find_context/2" do
    property "inserts unique ids that are sorted" do
      check all(ids <- uniq_list_of(non_negative_integer(), max_tries: 500)) do
        predictor =
          Enum.shuffle(ids)
          |> Enum.reduce(Sooth.Predictor.new(0), fn id, predictor ->
            {predictor, _, _} = Sooth.Predictor.find_context(predictor, id)
            predictor
          end)

        contexts = Enum.sort(ids) |> Enum.map(&Sooth.Context.new(&1))
        assert Aja.Vector.new(contexts) == predictor.contexts
      end
    end
  end

  describe "observe/2" do
    property "increments the counts of the observed events" do
      check all(
              events <- list_of(non_negative_integer(), max_tries: 500),
              ids <- list_of(non_negative_integer(), max_tries: 500)
            ) do
        predictor =
          Enum.reduce(ids, Sooth.Predictor.new(0), fn id, predictor ->
            Enum.reduce(events, predictor, fn event, predictor ->
              {predictor, _} = Sooth.Predictor.observe(predictor, id, event)
              predictor
            end)
          end)

        # Build a map of {id, event} -> count
        counts =
          Enum.reduce(ids, %{}, fn id, acc ->
            Enum.reduce(events, acc, fn event, acc ->
              Map.update(acc, {id, event}, 1, &(&1 + 1))
            end)
          end)

        # Verify all the statistic counts match the counts
        Enum.each(predictor.contexts, fn context ->
          Enum.each(context.statistics, fn stat ->
            assert Map.get(counts, {context.id, stat.event}) == stat.count
          end)
        end)
      end
    end
  end
end
