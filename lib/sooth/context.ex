defmodule Sooth.Context do
  @moduledoc """
  Provides the Context module for Sooth.

  This module is mainly used for internal implementation details of the Sooth.Predictor module
  and should not be used directly.
  """
  use TypedStruct

  alias Sooth.Statistic
  alias Sooth.Context

  typedstruct enforce: true do
    @typedoc "A Context of id/count/statistics"

    field(:id, non_neg_integer())
    field(:count, non_neg_integer())
    field(:statistic_set, :gb_sets.set())
    field(:statistic_objects, map())
  end

  @spec new(non_neg_integer()) :: Sooth.Context.t()
  @doc """
  Create a new context.

  ## Examples

      iex> Sooth.Context.new(0)
      #Sooth.Context<id: 0, count: 0, statistic_set: [], statistic_objects: %{}>
  """
  def new(id) do
    %Sooth.Context{id: id, count: 0, statistic_set: :gb_sets.new(), statistic_objects: %{}}
  end

  @spec observe(Sooth.Context.t(), non_neg_integer()) :: {Sooth.Context.t(), Sooth.Statistic.t()}
  @doc """
  Observe an event in a context.

  ## Examples

      iex> context = Sooth.Context.new(0)
      iex> {context, _} = Sooth.Context.observe(context, 3)
      iex> context
      #Sooth.Context<id: 0, count: 1, statistic_set: [3], statistic_objects: %{3 => %Sooth.Statistic{count: 1, event: 3}}>
  """
  def observe(context, event) do
    {context, statistic} =
      case find_statistic(context, event) do
        nil ->
          statistic = Statistic.new(event, 1)
          statistic_set = :gb_sets.add(event, context.statistic_set)
          {put_in(context.statistic_set, statistic_set), statistic}

        statistic ->
          {context, Statistic.increment(statistic)}
      end

    {%Context{
       context
       | count: context.count + 1,
         statistic_objects: Map.put(context.statistic_objects, event, statistic)
     }, statistic}
  end

  @spec find_statistic(Sooth.Context.t(), non_neg_integer()) :: Sooth.Statistic.t() | nil
  @doc """
  Find a statistic in a context.

  This is an implementation detail and should not be used directly.
  """
  def find_statistic(context, event) do
    Map.get(context.statistic_objects, event)
  end

  @spec fetch_statistic(Sooth.Context.t(), non_neg_integer()) ::
          {:ok, Sooth.Statistic.t()} | :error
  @doc """
  Fetch a statistic in a context.

  This is an implementation detail and should not be used directly.

  ## Examples

      iex> context = Sooth.Context.new(0)
      iex> Sooth.Context.fetch_statistic(context, 3)
      :error
      iex> {context, _} = Sooth.Context.observe(context, 3)
      iex> Sooth.Context.fetch_statistic(context, 3)
      {:ok, %Sooth.Statistic{count: 1, event: 3}}
  """
  def fetch_statistic(context, event) do
    Map.fetch(context.statistic_objects, event)
  end

  def walk_statistics(context) do
    Enum.map(:gb_sets.to_list(context.statistic_set), fn event ->
      Map.get(context.statistic_objects, event)
    end)
  end
end

defimpl Inspect, for: Sooth.Context do
  @doc false
  def inspect(
        %Sooth.Context{
          id: id,
          count: count,
          statistic_set: statistic_set,
          statistic_objects: statistic_objects
        },
        _opts
      ) do
    stat_set = inspect(:gb_sets.to_list(statistic_set))
    stat_objs = inspect(statistic_objects)

    "#Sooth.Context<id: #{id}, count: #{count}, statistic_set: #{stat_set}, statistic_objects: #{stat_objs}>"
  end
end
