defmodule LibLatLon.Info do
  @moduledoc """
  Main storage struct for holding information about any place/POI/address
  in the unified form.

  ## Example:

      LibLatLon.lookup {41.38777777777778, 2.197222222222222}

      %LibLatLon.Info{
        address: "Avinguda del Litoral, [...] España",
        bounds: %LibLatLon.Bounds{
          from: #Coord<[
            lat: 41.3876663,
            lon: 2.196602,
            fancy: "41°23´15.59868˝N,2°11´47.7672˝E"
          ]>,
          to: #Coord<[
            lat: 41.3917431,
            lon: 2.2031084,
            fancy: "41°23´30.27516˝N,2°12´11.19024˝E"
          ]>
        },
        coords: #Coord<[
          lat: 41.3899932,
          lon: 2.2000054,
          fancy: "41°23´23.97552˝N,2°12´0.01944˝E"
        ]>,
        details: %{
          city: "Barcelona",
          city_district: "Sant Martí",
          country: "España",
          country_code: "es",
          county: "BCN",
          postcode: "08020",
          road: "Avinguda del Litoral",
          state: "CAT",
          suburb: "la Vila Olímpica del Poblenou"
        },
        meta: %{
          licence: "Data © OpenStreetMap [...]",
          osm_id: "47123759",
          osm_type: "way",
          place_id: "82181109"
        }
      }

  """

  @typedoc """
  Main type to store geo point in unified form. See:

  * [`LibLatLon.Bounds.t`] for `bounds` field
  * [`LibLatLon.Coords.t`] for `coords` key

  `address` is a string, representing the whole address in human-readable form.

  `details` and `meta` are _not_ unified maps of fields, as returned
    by geo location provider. Their keys differ for different providers.
  """
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
  Mostly internal helper. You would unlikely call this function yourself.

  Gets the map as returned by geo location provider and contructs
    fields in unified format.
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

  @doc """
  The same as [`LibLatLon.Info.from_map/1`], but banged.
  """
  def from_map!([]), do: []
  def from_map!(%{} = input),
    do: with {:ok, result} <- from_map(input), do: result
  def from_map!([%{} = h | t]), do: [from_map!(h) | from_map!(t)]

  @doc """
  Formats the [`String.t`] representation of this struct according to
    the format given.

  Second parameter `format` might include `%{field}` inclusions
  which will be interpolated in the result with real values.

  ## Examples

      iex> info = LibLatLon.lookup({42, 3.14159265}, LibLatLon.Providers.Dummy)
      iex> LibLatLon.Info.format(info, "⚑ %{country}, %{city}, %{postcode}.")
      "⚑ España, Barcelona, 08021."
  """
  def format(%LibLatLon.Info{details: %{} = content}, format) when is_binary(format) do
    ~r|%{(.*?)}|
    |> Regex.replace(format, fn
      _, term ->
        content[String.to_atom(term)] || ""
    end)
    |> String.replace(~r|(?:\p{P}[\p{M}\p{Z}\n\r]*)+(\p{P})|u, "\\1")
  end
end
