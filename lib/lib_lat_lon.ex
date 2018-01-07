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
end
