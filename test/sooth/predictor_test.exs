defmodule SoothPredictorTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Sooth.Predictor

  doctest Sooth.Predictor

  test "creates empty predictor" do
    assert match?(%Predictor{error_event: 0, context_set: _, context_map: %{}}, Predictor.new(0))
  end

  describe "find_context/2" do
    property "inserts unique ids that are sorted" do
      check all(ids <- uniq_list_of(non_negative_integer(), max_tries: 500)) do
        predictor =
          Enum.shuffle(ids)
          |> Enum.reduce(Sooth.Predictor.new(0), fn id, predictor ->
            Sooth.Predictor.observe(predictor, id, 0)
          end)

        assert Enum.sort(ids) == :gb_sets.to_list(predictor.context_set)
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
            Enum.reduce(events, predictor, &Sooth.Predictor.observe(&2, id, &1))
          end)

        # Build a map of {id, event} -> count
        counts =
          Enum.reduce(ids, %{}, fn id, acc ->
            Enum.reduce(events, acc, fn event, acc ->
              Map.update(acc, {id, event}, 1, &(&1 + 1))
            end)
          end)

        # Verify all the statistic counts match the counts
        Enum.each(Map.values(predictor.context_map), fn context ->
          Enum.each(Map.values(context.statistic_objects), fn stat ->
            assert Map.get(counts, {context.id, stat.event}) == stat.count
          end)
        end)
      end
    end
  end

  describe "select/2" do
    test "selects the context with the highest count" do
      predictor =
        Predictor.new(0)
        |> Predictor.observe(1, 3)
        |> Predictor.observe(1, 2)
        |> Predictor.observe(2, 3)

      assert Predictor.select(predictor, 1, 2) == 3
      assert Predictor.select(predictor, 1, 1) == 2
      assert Predictor.select(predictor, 1, 3) == 0
      assert Predictor.count(predictor, 1) == 2
    end
  end

  describe "uncertainty/2" do
    test "has no uncertainty for a new context" do
      predictor = Predictor.new(0)
      assert Predictor.uncertainty(predictor, 0) == :error
      assert Predictor.count(predictor, 1) == 0
    end

    test "has zero uncertainty for a lone context" do
      predictor =
        Predictor.new(0)
        |> Predictor.observe(1, 3)

      assert match?({:ok, 0.0}, Predictor.uncertainty(predictor, 1))
    end

    test "has maximal uncertainty for a uniform distribution" do
      predictor =
        1..256
        |> Enum.reduce(Predictor.new(42), &Predictor.observe(&2, 1, &1))

      assert match?({:ok, 8.0}, Predictor.uncertainty(predictor, 1))
    end
  end

  describe "surprise" do
    test "has no surprise for a new context" do
      predictor = Predictor.new(0)
      assert Predictor.surprise(predictor, 0, 0) == :error
    end

    test "has no surprise for a new event" do
      predictor =
        Predictor.new(42)
        |> Predictor.observe(1, 3)

      assert Predictor.surprise(predictor, 1, 0) == :error
    end

    test "has zero surprise for a lone event" do
      predictor =
        Predictor.new(42)
        |> Predictor.observe(1, 3)

      assert Predictor.surprise(predictor, 1, 3) == {:ok, 0}
    end

    test "has uniform surprise for a uniform distribution" do
      predictor =
        1..256
        |> Enum.reduce(Predictor.new(42), &Predictor.observe(&2, 1, &1))

      assert Predictor.surprise(predictor, 1, 3) == {:ok, 8}
    end
  end

  describe "frequency" do
    test "returns zero for a new context" do
      predictor = Predictor.new(0)
      assert Predictor.frequency(predictor, 1, 3) == 0
    end

    test "returns zero for a new event" do
      predictor =
        Predictor.new(42)
        |> Predictor.observe(1, 3)

      assert Predictor.frequency(predictor, 1, 4) == 0
    end

    test "is one for a lone event" do
      predictor =
        Predictor.new(42)
        |> Predictor.observe(1, 3)

      assert Predictor.frequency(predictor, 1, 3) == 1
    end

    test "is uniform for a uniform distribution" do
      predictor =
        1..100
        |> Enum.reduce(Predictor.new(42), &Predictor.observe(&2, 1, &1))

      assert Predictor.frequency(predictor, 1, 3) == 0.01
    end
  end
end
