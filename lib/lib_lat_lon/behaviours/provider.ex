defmodule LibLatLon.Provider do
  @moduledoc """
  The default behaviour for all the geo providers.

  Implementations known:

  * `LibLatLon.Providers.OpenStreetMap`
  * `LibLatLon.Providers.GoogleMaps`

  Contributions are _very welcome_.
  """

  @doc "Returns a name of this provider to display"
  @callback name() :: binary()

  @doc """
  Performs either a normal lookup by any string or
    a reverse lookup by latitude and longitude
  """
  @callback lookup(LibLatLon.Coords.t() | String.t(), %{}) ::
              {:ok, LibLatLon.Info.t()} | {:error, any()}
end
