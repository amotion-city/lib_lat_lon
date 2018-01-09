defmodule LibLatLon.Bounds do
  @type t :: %__MODULE__{from: LibLatLon.Coords.t(), to: LibLatLon.Coords.t()}

  @fields ~w|from to|a

  defstruct @fields

  def from_lat_lon([lat1, lat2, lon1, lon2]) do
    [lat1, lat2, lon1, lon2] =
      Enum.map([lat1, lat2, lon1, lon2], &LibLatLon.Utils.safe_float/1)

    with {:ok, from } <- LibLatLon.Coords.coordinate({lat1, lon1}),
         {:ok, to} <- LibLatLon.Coords.coordinate({lat2, lon2}) do
      {:ok, %__MODULE__{from: from, to: to}}
    end
  end
end
