defmodule Sooth.Predictor do
  @moduledoc """
  Provides the Predictor module for Sooth.

  This is the main entry point for the Sooth library.
  """
  import Aja
  alias Aja.Vector
  alias Sooth.Context
  alias Sooth.Predictor

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "A Predictor of error_event/contexts"

    field(:error_event, non_neg_integer())
    field(:contexts, Vector.t(Context.t()))
  end

  @spec new(non_neg_integer()) :: Sooth.Predictor.t()
  @doc """
  Returns a new Sooth.Predictor.

  ## Parameters
  - `error_event` - The event to be returned by #select when no observations have been made for the context.

  ## Examples

      iex> Sooth.Predictor.new(2)
      %Sooth.Predictor{error_event: 2, contexts: vec([])}

  """
  def new(error_event) do
    %Sooth.Predictor{error_event: error_event, contexts: Vector.new()}
  end

  @spec count(Sooth.Predictor.t(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return the number of times the context has been observed.

  ## Parameters
  - `predictor` - The predictor that will count the context.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 2, 3)
      iex> Sooth.Predictor.count(predictor, 2)
      1
      iex> Sooth.Predictor.count(predictor, 3)
      0
  """
  def count(predictor, id) do
    {_, context, _} = find_context(predictor, id)
    context.count
  end

  @spec distribution(Sooth.Predictor.t(), non_neg_integer()) :: Aja.Vector.t(Sooth.Statistic.t())
  @doc """
  Return a vector that yields each observed event within the context together with its probability.

  ## Parameters
  - `predictor` - The predictor that will calculate the distribution.
  - `id` - A number that provides a context for the distribution.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> Sooth.Predictor.distribution(predictor, 0)
      vec([%Sooth.Statistic{event: 3, count: 1}])
  """
  def distribution(predictor, id) do
    {_, context, _} = find_context(predictor, id)
    context.statistics
  end

  @doc """
  Return a number indicating the frequency that the event has been observed within the given context.

  ## Parameters
  - `predictor` - The predictor that will calculate the frequency.
  - `id` - A number that provides a context for the frequency.
  - `event` - A number representing the observed event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 4)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 5)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 2)
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
    {_, context, _} = find_context(predictor, id)

    if context.count == 0 do
      0.0
    else
      {_, statistic, _} = Context.find_statistic(context, event)

      if statistic.count == 0 do
        0.0
      else
        statistic.count / context.count
      end
    end
  end

  @spec observe(Sooth.Predictor.t(), non_neg_integer(), non_neg_integer()) ::
          {map(), non_neg_integer()}
  @doc """
  Register an observation of the given event within the given context.

  ## Parameters
  - `predictor` - The predictor that will observe the event.
  - `id` - A number that provides a context for the event, allowing the predictor to maintain observation statistics for different contexts.
  - `event` - A number representing the observed event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> predictor
      %Sooth.Predictor{
        error_event: 0,
        contexts: vec([
          %Sooth.Context{id: 0, count: 1, statistics: vec([%Sooth.Statistic{event: 3, count: 1}])}
        ])
      }
  """
  def observe(predictor, id, event) do
    {predictor, context, index} = find_context(predictor, id)
    {context, statistic} = Context.observe(context, event)
    {put_in(predictor.contexts[index], context), statistic.count}
  end

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

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 4)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 5)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 2)
      iex> Sooth.Predictor.select(predictor, 0, 1)
      3
      iex> Sooth.Predictor.select(predictor, 0, 2)
      3
      iex> Sooth.Predictor.select(predictor, 0, 3)
      4
      iex> Sooth.Predictor.select(predictor, 0, 4)
      5
      iex> Sooth.Predictor.select(predictor, 1, 1)
      2
      iex> Sooth.Predictor.select(predictor, 0, 90)
      0

  """
  def select(predictor, id, limit) do
    {_, context, _} = find_context(predictor, id)

    cond do
      limit == 0 ->
        predictor.error_event

      limit > context.count ->
        predictor.error_event

      true ->
        select_event(
          context.statistics,
          limit,
          0,
          vec_size(context.statistics) - 1,
          predictor.error_event
        )
    end
  end

  defp select_event(statistics, limit, index, last, err) when index <= last do
    statistic = statistics[index]

    cond do
      limit > statistic.count ->
        select_event(statistics, limit - statistic.count, index + 1, last, err)

      true ->
        statistic.event
    end
  end

  defp select_event(_, _, _, _, err), do: err

  def find_context(%Predictor{contexts: contexts} = predictor, id) do
    case binary_search(contexts, id, 0, vec_size(contexts) - 1) do
      {:found, context, index} -> {predictor, context, index}
      {:not_found, context, index} -> {insert_context(predictor, index, context), context, index}
    end
  end

  defp binary_search(contexts, id, low, high) when low <= high do
    mid = low + div(high - low, 2)
    context = contexts[mid]

    cond do
      context.id == id -> {:found, context, mid}
      context.id > id and mid == 0 -> {:not_found, Context.new(id), low}
      context.id > id -> binary_search(contexts, id, low, mid - 1)
      context.id < id -> binary_search(contexts, id, mid + 1, high)
    end
  end

  defp binary_search(_, id, low, _), do: {:not_found, Context.new(id), low}

  defp insert_context(%Predictor{contexts: contexts} = predictor, index, context) do
    {left, right} = Vector.split(contexts, index)
    %Predictor{predictor | contexts: Vector.append(left, context) +++ right}
  end
end
