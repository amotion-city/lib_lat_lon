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
              details: map.details,
              meta: map.meta,
              address: map.display
            }}
    end
  end
  def from_map(list) when is_list(list), do: {:ok, from_map!(list)}

  def from_map!([]), do: []
  def from_map!(%{} = input),
    do: with {:ok, result} <- from_map(input), do: result
  def from_map!([%{} = h | t]), do: [from_map!(h) | from_map!(t)]

  def format(%LibLatLon.Info{details: %{} = content}, format) when is_binary(format) do
    ~r|%{(.*?)}|
    |> Regex.replace(format, fn
      _, term ->
        content[String.to_atom(term)]
    end)
    |> String.replace(~r|(?:\p{P}[\p{M}\p{Z}\n\r]*)+(\p{P})|u, "\\1")
  end
end
