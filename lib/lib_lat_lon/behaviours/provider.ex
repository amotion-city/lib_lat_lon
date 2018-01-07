defmodule LibLatLon.Provider do
@moduledoc """
  The default behaviour for all the geo providers.
  """

  @doc "Returns a name of this provider to display"
  @callback name() :: binary()

  @doc "Performs a reverse lookup by latitude and longitude"
  @callback lookup(LibLatLon.Coords.t) :: LibLatLon.Info.t
end