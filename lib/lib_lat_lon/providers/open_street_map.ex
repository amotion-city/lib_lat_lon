defmodule LibLatLon.Providers.OpenStreetMap do
  @moduledoc """
    `OpenStreetMap` provider implementation.
  """

  @behaviour LibLatLon.Provider

  @server_url "https://nominatim.openstreetmap.org"
  @search Enum.join([@server_url, "search"], "/")
  @reverse Enum.join([@server_url, "reverse"], "/")

  @defaults %{"accept-language": "en"}
  @reverse_defaults %{format: :json, zoom: 16, addressdetails: 1}
  @search_defaults %{format: :json, polygon_geojson: 1, viewbox: ""}

  @doc false
  def name, do: "Open Street Map"

  @doc """
  Implements a lookup for `OpenStreetMap` provider. Returns either
    `{:ok, %LibLatLon.Info{}}` or `{:error, reason}` tuple.

  Used internally by `LibLatLon.lookup/1`.
  """
  @spec lookup(LibLatLon.Coords.t() | String.t(), %{}) ::
          {:ok, LibLatLon.Info.t()} | {:error, any()}
  def lookup(input, opts \\ @defaults)

  # "https://nominatim.openstreetmap.org/reverse?format=json&
  #           accept-language={{ language }}&lat={{ latitude }}&
  #           lon={{ longitude }}&zoom={{ zoom }}&addressdetails=1"
  def lookup(%LibLatLon.Coords{lat: lat, lon: lon}, opts) do
    query =
      opts
      |> Map.merge(@reverse_defaults)
      |> Map.merge(%{lat: lat, lon: lon})

    [@reverse, URI.encode_query(query)]
    |> Enum.join("?")
    |> do_lookup()
  end

  # # "https://nominatim.openstreetmap.org/search?format=json
  #             q=Barcelona+c%2Fde+Marina+16&polygon_geojson=1&viewbox=
  def lookup(address, opts) when is_binary(address) do
    query =
      opts
      |> Map.merge(@search_defaults)
      |> Map.merge(%{q: address})
      |> URI.encode_query()

    [@search, query]
    |> Enum.join("?")
    |> do_lookup()
  end

  ##############################################################################

  # %{
  #   "address" => %{
  #     "city" => "Barcelona",
  #     "city_district" => "Sant Martí",
  #     "country" => "Spain",
  #     "country_code" => "es",
  #     "county" => "BCN",
  #     "postcode" => "08020",
  #     "road" => "Avinguda del Litoral",
  #     "state" => "Catalonia",
  #     "suburb" => "la Vila Olímpica del Poblenou"
  #   },
  #   "boundingbox" => ["41.3876663", "41.3917431", "2.196602", "2.2031084"],
  #   "display_name" => "Avinguda del Litoral, [...], Barcelona, BCN, Catalonia, 08020, Spain",
  #   "lat" => "41.3899932",
  #   "licence" => "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
  #   "lon" => "2.2000054",
  #   "osm_id" => "47123759",
  #   "osm_type" => "way",
  #   "place_id" => "82181109"
  # }
  defp normalize(%{} = input) do
    output = %{
      details: LibLatLon.Utils.keywordize(input["address"]),
      bounds: input["boundingbox"],
      display: input["display_name"],
      lat: input["lat"],
      lon: input["lon"],
      meta:
        input
        |> Map.take(~w|type importance osm_type osm_id place_id licence|)
        |> LibLatLon.Utils.keywordize()
    }

    {:ok, output}
  end

  defp normalize(list) when is_list(list), do: {:ok, normalize!(list)}

  defp normalize!([]), do: []
  defp normalize!(%{} = input), do: with({:ok, result} <- normalize(input), do: result)
  defp normalize!([%{} = h | t]), do: [normalize!(h) | normalize!(t)]

  defp do_lookup(query) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(query),
         {:ok, result} <- Jason.decode(body),
         {:ok, result} <- normalize(result),
         {:ok, result} <- LibLatLon.Info.from_map(result) do
      result
    else
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, error} ->
        {:error, error}

      :error ->
        {:error, :unknown}
    end
  end
end
