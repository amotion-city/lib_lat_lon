defmodule LibLatLon.Provider do
  @moduledoc """
  The default behaviour for all the geo providers.
  """

  @doc "Returns a name of this provider to display"
  @callback name() :: binary()

  @doc """
  Performs either a normal lookup by any string or
    a reverse lookup by latitude and longitude
  """
  @callback lookup(LibLatLon.Coords.t() | binary()) :: LibLatLon.Info.t()
end
