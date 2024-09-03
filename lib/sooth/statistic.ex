defmodule Sooth.Statistic do
  @moduledoc """
  A simple data structure for tracking event counts.
  """

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "A Statistic of event/count"

    field(:event, non_neg_integer())
    field(:count, non_neg_integer())
  end

  @spec new(non_neg_integer(), non_neg_integer()) :: Sooth.Statistic.t()
  @doc """
  Create a new statistic.

  ## Examples

      iex> Sooth.Statistic.new(0, 0)
      %Sooth.Statistic{event: 0, count: 0}
  """
  def new(event, count) do
    %Sooth.Statistic{event: event, count: count}
  end

  @spec increment(Sooth.Statistic.t()) :: Sooth.Statistic.t()
  @doc """
  Increment the count of a statistic.

  ## Examples

      iex> Sooth.Statistic.increment(%Sooth.Statistic{event: 0, count: 0})
      %Sooth.Statistic{event: 0, count: 1}
  """
  def increment(%Sooth.Statistic{count: count} = statistic) do
    %Sooth.Statistic{statistic | count: count + 1}
  end
end
