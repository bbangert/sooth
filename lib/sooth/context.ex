defmodule Sooth.Context do
  import Aja
  alias Aja.Vector
  alias Sooth.Statistic
  alias Sooth.Context
  use TypedStruct

  typedstruct enforce: true do
    @typedoc "A Context of id/count/statistics"

    field(:id, non_neg_integer())
    field(:count, non_neg_integer())
    field(:statistics, Vector.t(Statistic.t()))
  end

  @spec new(non_neg_integer()) :: Sooth.Context.t()
  @doc """
  Create a new context.

  ## Examples

      iex> Sooth.Context.new(0)
      %Sooth.Context{id: 0, count: 0, statistics: vec([])}
  """
  def new(id) do
    %Sooth.Context{id: id, count: 0, statistics: Vector.new()}
  end

  @spec observe(Sooth.Context.t(), non_neg_integer()) :: {Sooth.Context.t(), Sooth.Statistic.t()}
  @doc """
  Observe an event in a context.

  ## Examples

      iex> context = Sooth.Context.new(0)
      iex> {context, _} = Sooth.Context.observe(context, 3)
      iex> context
      %Sooth.Context{id: 0, count: 1, statistics: vec([%Sooth.Statistic{event: 3, count: 1}])}
  """
  def observe(context, event) do
    {context, statistic, index} = find_statistic(context, event)

    {%Context{
       put_in(context.statistics[index], Statistic.increment(statistic))
       | count: context.count + 1
     }, statistic}
  end

  @spec find_statistic(Sooth.Context.t(), non_neg_integer()) ::
          {Sooth.Context.t(), Sooth.Statistic.t(), non_neg_integer()}
  def find_statistic(%Context{statistics: statistics} = context, event) do
    case binary_search(statistics, event, 0, vec_size(statistics) - 1) do
      {:found, statistic, index} ->
        {context, statistic, index}

      {:not_found, statistic, index} ->
        {insert_statistic(context, index, statistic), statistic, index}
    end
  end

  defp binary_search(statistics, event, low, high) when low <= high do
    mid = low + div(high - low, 2)
    statistic = statistics[mid]

    cond do
      statistic.event == event -> {:found, statistic, mid}
      statistic.event > event and mid == 0 -> {:not_found, Statistic.new(event, 0), low}
      statistic.event > event -> binary_search(statistics, event, low, mid - 1)
      statistic.event < event -> binary_search(statistics, event, mid + 1, high)
    end
  end

  defp binary_search(_, event, low, _), do: {:not_found, Statistic.new(event, 0), low}

  defp insert_statistic(%Context{statistics: statistics} = context, index, statistic) do
    {left, right} = Vector.split(statistics, index)
    %Context{context | statistics: Vector.append(left, statistic) +++ right}
  end
end
