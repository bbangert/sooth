defmodule Sooth.Predictor do
  @moduledoc """
  Provides the Predictor module for Sooth.

  This is the main entry point for the Sooth library.
  """
  import Aja
  import Math
  alias Aja.Vector
  alias Sooth.Context
  alias Sooth.Predictor

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "A Predictor of error_event/contexts"

    field(:error_event, non_neg_integer())
    field(:contexts, Vector.t(Context.t()))
  end

  @spec new(non_neg_integer()) :: Predictor.t()
  @doc """
  Returns a new Sooth.Predictor.

  ## Parameters
  - `error_event` - The event to be returned by #select when no observations have been made for the context.

  ## Examples

      iex> Sooth.Predictor.new(2)
      %Sooth.Predictor{error_event: 2, contexts: vec([])}

  """
  def new(error_event), do: %Predictor{error_event: error_event, contexts: Vector.new()}

  @spec count(Predictor.t(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return the number of times the context has been observed.

  ## Parameters
  - `predictor` - The predictor that will count the context.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 2, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 2, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 2, 2)
      iex> Sooth.Predictor.count(predictor, 2)
      3
      iex> Sooth.Predictor.count(predictor, 3)
      0
  """
  def count(predictor, id) do
    {_, context, _} = find_context(predictor, id)
    context.count
  end

  @spec size(Predictor.t(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Return the number of different events that have been observed within the given context.

  ## Parameters
  - `predictor` - The predictor that will calculate the size.
  - `id` - A number that provides a context for observations.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 1)
      iex> Sooth.Predictor.size(predictor, 0)
      2
  """
  def size(predictor, id) do
    {_, context, _} = find_context(predictor, id)
    vec_size(context.statistics)
  end

  @spec distribution(Predictor.t(), non_neg_integer()) :: Vector.t(Sooth.Statistic.t())
  @doc """
  Return a stream that yields each observed event within the context together with its
  probability.

  ## Parameters
  - `predictor` - The predictor that will calculate the distribution.
  - `id` - A number that provides a context for the distribution.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 2)
      iex> Sooth.Predictor.distribution(predictor, 0) |> Enum.to_list()
      [{2, 0.5}, {3, 0.5}]
      iex> Sooth.Predictor.distribution(predictor, 1)
      nil
  """
  def distribution(predictor, id) do
    {_, context, _} = find_context(predictor, id)

    cond do
      vec_size(context.statistics) == 0 -> nil
      true -> Stream.map(context.statistics, &{&1.event, &1.count / context.count})
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
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 4)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 5)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 2)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 4)
      iex> Sooth.Predictor.uncertainty(predictor, 0)
      1.5
      iex> Sooth.Predictor.uncertainty(predictor, 1)
      1.584962500721156
      iex> Sooth.Predictor.uncertainty(predictor, 2)
      nil
  """
  def uncertainty(predictor, id) do
    {_ , context, _} = find_context(predictor, id)
    cond do
      context.count == 0 -> nil
      true -> Enum.reduce(context.statistics, 0.0, fn stat, acc ->
        frequency = stat.count / context.count
        acc - (frequency * log2(frequency))
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

  @spec observe(Predictor.t(), non_neg_integer(), non_neg_integer()) ::
          {Predictor.t(), non_neg_integer()}
  @doc """
  Register an observation of the given event within the given context.

  ## Parameters
  - `predictor` - The predictor that will observe the event.
  - `id` - A number that provides a context for the event, allowing the predictor to maintain
           observation statistics for different contexts.
  - `event` - A number representing the observed event.

  ## Examples

      iex> predictor = Sooth.Predictor.new(0)
      iex> {predictor, count} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> predictor
      %Sooth.Predictor{
        error_event: 0,
        contexts: vec([
          %Sooth.Context{id: 0, count: 1, statistics: vec([%Sooth.Statistic{event: 3, count: 1}])}
        ])
      }
      iex> count
      1
  """
  def observe(predictor, id, event) do
    {predictor, context, index} = find_context(predictor, id)
    {context, statistic} = Context.observe(context, event)
    {put_in(predictor.contexts[index], context), statistic.count}
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
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 4)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 4)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 5)
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
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 0, 5)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 2)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 3)
      iex> {predictor, _} = Sooth.Predictor.observe(predictor, 1, 4)
      iex> Sooth.Predictor.surprise(predictor, 0, 3)
      0.5849625007211563
      iex> Sooth.Predictor.surprise(predictor, 0, 4)
      nil
      iex> Sooth.Predictor.surprise(predictor, 1, 2)
      1.5849625007211563
  """
  def surprise(predictor, id, event) do
    {_, context, _} = find_context(predictor, id)

    cond do
      context.count == 0 ->
        nil

      true ->
        {_, statistic, _} = Context.find_statistic(context, event)

        if statistic.count == 0 do
          nil
        else
          -log2(statistic.count / context.count)
        end
    end
  end

  @spec find_context(Predictor.t(), non_neg_integer()) ::
          {Predictor.t(), Context.t(), non_neg_integer()}
  @doc """
  Find a context in the predictor.

  This is an implementation detail and should not be used directly.
  """
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
