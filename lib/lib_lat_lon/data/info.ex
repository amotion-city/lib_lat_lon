defmodule LibLatLon.Info do
  @type t :: %__MODULE__{
          bounds: LibLatLon.Bounds.t(),
          coords: LibLatLon.Coords.t(),
          details: map(),
          meta: map(),
          address: binary()
        }

  @fields ~w|bounds coords details meta address|a

  defstruct @fields

  @doc """
      %{
        bounds: ["41.3876663", "41.3917431", "2.196602", "2.2031084"],
        details: %{
          "city" => "Barcelona",
          "city_district" => "Sant Martí",
          "country" => "Spain",
          "country_code" => "es",
          "county" => "BCN",
          "postcode" => "08020",
          "road" => "Avinguda del Litoral",
          "state" => "Catalonia",
          "suburb" => "la Vila Olímpica del Poblenou"
        },
        display: "Avinguda del Litoral, la Vila Olímpica del Poblenou, Sant Martí, Barcelona, BCN, Catalonia, 08020, Spain",
        lat: "41.3899932",
        lon: "2.2000054",
        meta: %{
          "licence" => "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
          "osm_id" => "47123759",
          "osm_type" => "way",
          "place_id" => "82181109"
        }
      }
  """

  def from_map(%{} = map) do
    with {:ok, bounds} <- LibLatLon.Bounds.from_lat_lon(map.bounds),
         {:ok, coords} <- LibLatLon.Coords.coordinate({map.lat, map.lon}) do
      {:ok, %__MODULE__{
              bounds: bounds,
              coords: coords,
              details: map.details, meta: map.meta,
              address: map.display
            }}
    end
  end
end
