defmodule LibLatLon do
  @moduledoc """
  Documentation for LibLatLon.
  """

  @doc """
  Hello world.

  ## Examples

      iex> LibLatLon.hello
      :world

  """
  def hello do
    :world
  end

  defprotocol LibLatLon.Coord do
    @doc "Produces `LibLatLon.Coords` from any source given"
    def as_latlon(data)
  end

  defmodule Utils do
    def safe_float(v) when is_float(v), do: v
    def safe_float(v) when is_integer(v), do: v * 1.0
    def safe_float(v) when is_binary(v) do
      case Float.parse(v) do
        {float, ""} -> float
        {float, _} -> float
        :error -> 0.0
      end
    end
  end
end
