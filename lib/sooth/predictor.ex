defmodule Sooth.Predictor do
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
  def new(error_event) do
    %Sooth.Predictor{error_event: error_event, contexts: Vector.new()}
  end

  @spec observe(Sooth.Predictor.t(), non_neg_integer(), non_neg_integer()) ::
          {map(), non_neg_integer()}
  @doc """
  Register an observation of the given event within the given context.

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
