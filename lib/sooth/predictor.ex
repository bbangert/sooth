defmodule Sooth.Predictor do
  @moduledoc """
  Provides the Predictor module for Sooth.

  This is the main entry point for the Sooth library.
  """
  use TypedStruct

  import Math

  alias Sooth.Context
  alias Sooth.Predictor

  typedstruct enforce: true do
    @typedoc "A Predictor of error_event/contexts"

    field(:error_event, non_neg_integer())
    field(:context_set, :gb_sets.set())
    field(:context_map, map())
  end

  @spec new(non_neg_integer()) :: Sooth.Predictor.t()
  @doc """
  Returns a new Sooth.Predictor.

  ## Parameters
  - `error_event` - The event to be returned by #select when no observations have been made for the context.

  ## Examples

      iex> Sooth.Predictor.new(2)
      #Sooth.Predictor<error_event: 2, context_set: [], context_map: %{}>
  """
  def new(error_event),
    do: %Predictor{error_event: error_event, context_set: :gb_sets.new(), context_map: %{}}

  @spec count(Predictor.t(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return the number of times the context has been observed.

  ## Parameters
  - `predictor` - The predictor that will count the context.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor =
      ...>  Sooth.Predictor.new(0)
      ...>  |> Sooth.Predictor.observe(2, 3)
      ...>  |> Sooth.Predictor.observe(2, 3)
      ...>  |> Sooth.Predictor.observe(2, 2)
      iex> Sooth.Predictor.count(predictor, 2)
      3
      iex> Sooth.Predictor.count(predictor, 3)
      0
  """
  def count(predictor, id) do
    case Map.get(predictor.context_map, id) do
      nil -> 0
      context -> context.count
    end
  end

  @spec size(Predictor.t(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return the number of different events that have been observed within the given context.

  ## Parameters
  - `predictor` - The predictor that will calculate the size.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      ...>  |> Sooth.Predictor.observe(0, 3)
      ...>  |> Sooth.Predictor.observe(0, 3)
      ...>  |> Sooth.Predictor.observe(0, 3)
      ...>  |> Sooth.Predictor.observe(0, 1)
      iex> Sooth.Predictor.size(predictor, 0)
      2
  """
  def size(predictor, id) do
    case Map.get(predictor.context_map, id) do
      nil -> 0
      context -> map_size(context.statistic_objects)
    end
  end

  @spec distribution(Predictor.t(), non_neg_integer()) :: nil | list({non_neg_integer(), float()})
  @doc """
  Return a stream that yields each observed event within the context together with its
  probability.

  ## Parameters
  - `predictor` - The predictor that will calculate the distribution.
  - `id` - A number that provides a context for the distribution.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 2)
      iex> Sooth.Predictor.distribution(predictor, 0)
      [{2, 0.5}, {3, 0.5}]
      iex> Sooth.Predictor.distribution(predictor, 1)
      nil
  """
  def distribution(predictor, id) do
    case Map.get(predictor.context_map, id) do
      nil -> nil
      context -> Enum.map(Context.walk_statistics(context), &{&1.event, &1.count / context.count})
    end
  end

  @doc """
  Return a number indicating how uncertain the predictor is about which event is likely
  to be observed after the given context. Note that nil will be returned if the context
  has never been observed.

  Returns:
    The uncertainty, which is calculated to be the Shannon entropy of the `distribution`
    over the context.

  ## Parameters
  - `predictor` - The predictor that will calculate the uncertainty.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 4)
      ...> |> Sooth.Predictor.observe(0, 5)
      ...> |> Sooth.Predictor.observe(1, 2)
      ...> |> Sooth.Predictor.observe(1, 3)
      ...> |> Sooth.Predictor.observe(1, 4)
      iex> Sooth.Predictor.uncertainty(predictor, 0)
      {:ok, 1.5}
      iex> Sooth.Predictor.uncertainty(predictor, 1)
      {:ok, 1.584962500721156}
      iex> Sooth.Predictor.uncertainty(predictor, 2)
      :error
  """
  def uncertainty(predictor, id) do
    with {:ok, context} <- Map.fetch(predictor.context_map, id) do
      Enum.reduce(Map.values(context.statistic_objects), {:ok, 0.0}, fn stat, {:ok, acc} ->
        frequency = stat.count / context.count
        {:ok, acc - frequency * log2(frequency)}
      end)
    end
  end

  @spec frequency(Predictor.t(), non_neg_integer(), non_neg_integer()) :: float()
  @doc """
  Return a number indicating the frequency that the event has been observed within the
  given context.

  ## Parameters
  - `predictor` - The predictor that will calculate the frequency.
  - `id` - A number that provides a context for the frequency.
  - `event` - A number representing the observed event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 4)
      ...> |> Sooth.Predictor.observe(0, 5)
      ...> |> Sooth.Predictor.observe(1, 2)
      iex> Sooth.Predictor.frequency(predictor, 0, 3)
      0.5
      iex> Sooth.Predictor.frequency(predictor, 0, 4)
      0.25
      iex> Sooth.Predictor.frequency(predictor, 0, 5)
      0.25
      iex> Sooth.Predictor.frequency(predictor, 1, 2)
      1.0
  """
  def frequency(predictor, id, event) do
    with {:ok, context} <- Map.fetch(predictor.context_map, id),
         {:ok, statistic} <- Context.fetch_statistic(context, event) do
      statistic.count / context.count
    else
      _ -> 0.0
    end
  end

  @spec observe(Predictor.t(), non_neg_integer(), non_neg_integer()) :: Predictor.t()
  @doc """
  Register an observation of the given event within the given context.

  ## Parameters
  - `predictor` - The predictor that will observe the event.
  - `id` - A number that provides a context for the event, allowing the predictor to maintain observation statistics for different contexts.
  - `event` - A number representing the observed event.

  ## Options
  - `:include_count` - If this option is given, the function will return the count of the context.
  - `:include_statistic` - If this option is given, the function will return the statistic of the event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, count} = Sooth.Predictor.observe(predictor, 0, 3, :include_count)
      iex> predictor
      #Sooth.Predictor<error_event: 0, context_set: [0], context_map: %{0 => #Sooth.Context<id: 0, count: 1, statistic_set: [3], statistic_objects: %{3 => %Sooth.Statistic{count: 1, event: 3}}>}>
      iex> count
      1
  """
  def observe(predictor, id, event) do
    {context, _} = observe(predictor, id, event, :include_statistic)
    context
  end

  @spec observe(
          Predictor.t(),
          non_neg_integer(),
          non_neg_integer(),
          :include_count
        ) :: {Predictor.t(), non_neg_integer()}
  def observe(predictor, id, event, :include_count) do
    {context, statistic} = observe(predictor, id, event, :include_statistic)
    {context, statistic.count}
  end

  @spec observe(
          Predictor.t(),
          non_neg_integer(),
          non_neg_integer(),
          :include_statistic
        ) :: {Predictor.t(), Sooth.Statistic.t()}
  def observe(predictor, id, event, :include_statistic) do
    {predictor, context} =
      case Map.get(predictor.context_map, id) do
        nil ->
          context = Context.new(id)
          {put_in(predictor.context_set, :gb_sets.add(id, predictor.context_set)), context}

        context ->
          {predictor, context}
      end

    {context, statistic} = Context.observe(context, event)
    {put_in(predictor.context_map, Map.put(predictor.context_map, id, context)), statistic}
  end

  @spec select(Predictor.t(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return an event that may occur in the given context, based on the limit, which should be
  between 1 and #count. The event is selected by iterating through all observed events for
  the context, subtracting the observation count of each event from the limit until it is
  zero or less.

  Returns:
    An event that has been previously observed in the given context, or the error_event
    if the `count` of the context is zero, or if limit exceeds the `count` of the context.

  ## Parameters
  - `predictor` - The predictor that will select the event.
  - `id` - A number that provides a context for observations.
  - `limit` - The total number of event observations to be analysed before returning a event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(99)
      ...> |> Sooth.Predictor.observe(1, 4)
      ...> |> Sooth.Predictor.observe(1, 3)
      ...> |> Sooth.Predictor.observe(1, 4)
      ...> |> Sooth.Predictor.observe(1, 5)
      iex> Sooth.Predictor.select(predictor, 1, 1)
      3
      iex> Sooth.Predictor.select(predictor, 1, 2)
      4
      iex> Sooth.Predictor.select(predictor, 1, 3)
      4
      iex> Sooth.Predictor.select(predictor, 1, 4)
      5
      iex> Sooth.Predictor.select(predictor, 0, 0)
      99
      iex> Sooth.Predictor.select(predictor, 1, 5)
      99

  """
  def select(predictor, _id, 0), do: predictor.error_event

  def select(predictor, id, limit) do
    with {:ok, ctx} when limit <= ctx.count <- Map.fetch(predictor.context_map, id) do
      select_event(:gb_sets.iterator(ctx.statistic_set), limit, ctx.statistic_objects)
    else
      _ -> predictor.error_event
    end
  end

  defp select_event(stat_iterator, limit, stat_map) do
    {stat_int, stat_iterator} = :gb_sets.next(stat_iterator)

    case Map.fetch!(stat_map, stat_int) do
      stat when limit > stat.count -> select_event(stat_iterator, limit - stat.count, stat_map)
      stat -> stat.event
    end
  end

  @doc """
  Return a number indicating the surprise received by the predictor when it observed
  the given event within the given context. Note that nil will be returned if the
  event has never been observed within the context.

  Returns:
    The surprise, which is calculated to be the Shannon pointwise mutual information
    of the event according to the `distribution` over the context.

  ## Parameters
  - `predictor` - The predictor that will calculate the surprise.
  - `id` - A number that provides a context for observations.
  - `event` - A number representing the observed event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(9)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 3)
      ...> |> Sooth.Predictor.observe(0, 5)
      ...> |> Sooth.Predictor.observe(1, 2)
      ...> |> Sooth.Predictor.observe(1, 3)
      ...> |> Sooth.Predictor.observe(1, 4)
      iex> Sooth.Predictor.surprise(predictor, 0, 3)
      {:ok, 0.5849625007211563}
      iex> Sooth.Predictor.surprise(predictor, 0, 4)
      :error
      iex> Sooth.Predictor.surprise(predictor, 1, 2)
      {:ok, 1.5849625007211563}
  """
  def surprise(predictor, id, event) do
    with {:ok, context} <- Map.fetch(predictor.context_map, id),
         {:ok, statistic} <- Context.fetch_statistic(context, event) do
      {:ok, -log2(statistic.count / context.count)}
    end
  end
end

defimpl Inspect, for: Sooth.Predictor do
  def inspect(
        %Sooth.Predictor{
          error_event: error_event,
          context_set: context_set,
          context_map: context_map
        } = _predictor,
        _opts
      ) do
    context_set = inspect(:gb_sets.to_list(context_set))
    context_map = inspect(context_map)

    "#Sooth.Predictor<error_event: #{inspect(error_event)}, context_set: #{context_set}, context_map: #{context_map}>"
  end
end
