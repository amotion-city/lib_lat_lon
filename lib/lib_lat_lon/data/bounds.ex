defmodule LibLatLon.Bounds do
  @moduledoc """
  Convenient storage for geo bounds.
  """

  @typedoc """
  The `Bouds` struct has two fields (`from` and `to`).

  * `from` denoting the _northeast_ boundary, and
  * `to` denoting the _southwest_ boundary.

  # Example

  _GoogleMaps API_ returns the same structure from geocoding requests:

      %{...
        "geometry" => %{
          "bounds" => %{
            "northeast" => %{"lat" => 41.3884209, "lng" => 2.1982486},
            "southwest" => %{"lat" => 41.3874997, "lng" => 2.1970767}
          }
          ...

  """
  @type t :: %__MODULE__{from: LibLatLon.Coords.t(), to: LibLatLon.Coords.t()}

  @fields ~w|from to|a

  defstruct @fields

  @doc false
  def from_lat_lon([lat1, lat2, lon1, lon2]) do
    [lat1, lat2, lon1, lon2] = Enum.map([lat1, lat2, lon1, lon2], &LibLatLon.Utils.strict_float/1)

    with {:ok, from} <- LibLatLon.Coords.coordinate({lat1, lon1}),
         {:ok, to} <- LibLatLon.Coords.coordinate({lat2, lon2}) do
      {:ok, %__MODULE__{from: from, to: to}}
    end
  end
end
