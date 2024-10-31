# Benchmarks the core Sooth.Predictor functions for markov models.

alias Sooth.Predictor

# Generate a large list of numbers
unique_numbers = Enum.to_list(1..10_000)
same_numbers = Enum.map(unique_numbers, fn _ -> 1 end)
half_nummbers = Enum.to_list(1..5_000)

# Generate a large list of events, consisting of pairs of numbers
event_ids = Enum.zip(unique_numbers, unique_numbers)
events_with_ids = Enum.zip(event_ids, unique_numbers)

events_mixed = Enum.zip(half_nummbers, half_nummbers) ++ Enum.zip(half_nummbers, half_nummbers)
events_mixed_with_unique_ids = Enum.zip(events_mixed, unique_numbers)

preloaded_model =
  Enum.reduce(events_with_ids, Predictor.new(0), fn {event, id}, model ->
    Predictor.observe(model, event, id)
  end)

Benchee.run(
  %{
    "Sooth.Predictor.observe" => fn {model, events} ->
      Enum.reduce(events, model, fn {event, id}, model -> Predictor.observe(model, event, id) end)
    end
  },
  inputs: %{
    "unique events and unique ids" => {Predictor.new(0), events_with_ids},
    "seen events and seen ids" => {preloaded_model, Enum.zip(event_ids, same_numbers)},
    "50/50 unique events and seen ids" =>
      {Predictor.new(0), Enum.zip(events_mixed, same_numbers)},
    "50/50 seen events and unique ids" => {preloaded_model, events_mixed_with_unique_ids}
  },
  memory_time: 2
)

Benchee.run(%{
  "Sooth.Predictor.fetch_random_select" => fn ->
    Enum.map(event_ids, fn event -> Predictor.fetch_random_select(preloaded_model, event) end)
  end
})
