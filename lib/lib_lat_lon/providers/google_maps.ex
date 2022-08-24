defmodule LibLatLon.Providers.GoogleMaps do
  @moduledoc """
    `GoogleMaps` provider implementation.
  """

  @behaviour LibLatLon.Provider

  @server_url "https://maps.googleapis.com"

  @search Enum.join([@server_url, "maps/api/geocode/json"], "/")
  @reverse Enum.join([@server_url, "maps/api/geocode/json"], "/")

  @defaults %{language: "en"}

  @doc false
  def name, do: "Google Maps"

  @doc """
  Implements a lookup for `GoogleMaps` provider. Returns either
    `{:ok, %LibLatLon.Info{}}` or `{:error, reason}` tuple.

  Used internally by `LibLatLon.lookup/1`.
  """
  @spec lookup(LibLatLon.Coords.t() | String.t(), %{}) ::
          {:ok, LibLatLon.Info.t()} | {:error, any()}
  def lookup(input, opts \\ %{})

  # "https://maps.googleapis.com/maps/api/geocode/json?"
  def lookup(%LibLatLon.Coords{lat: lat, lon: lon}, opts) do
    query =
      defaults()
      |> Map.merge(opts)
      |> Map.put(:latlng, "#{lat},#{lon}")

    [@reverse, URI.encode_query(query)]
    |> Enum.join("?")
    |> do_lookup()
  end

  # "https://maps.googleapis.com/maps/api/geocode/json?"
  def lookup(address, opts) when is_binary(address) do
    query =
      defaults()
      |> Map.merge(opts)
      |> Map.put(:address, address)
      |> URI.encode_query()

    [@search, query]
    |> Enum.join("?")
    |> do_lookup()
  end

  ##############################################################################

  defp defaults do
    Map.put(@defaults, :key, System.get_env("GOOGLE_MAPS_API_KEY") || Application.get_env(:lib_lat_lon, :google_maps_api_key, nil))
  end

  # %{
  #   "address_components" => [
  #     %{
  #       "long_name" => "Torre Mapfre",
  #       "short_name" => "Torre Mapfre",
  #       "types" => ["premise"]
  #     },
  #     %{
  #       "long_name" => "Barcelona",
  #       "short_name" => "Barcelona",
  #       "types" => ["locality", "political"]
  #     },
  #     %{
  #       "long_name" => "Barcelona",
  #       "short_name" => "Barcelona",
  #       "types" => ["administrative_area_level_2", "political"]
  #     },
  #     %{
  #       "long_name" => "Catalunya",
  #       "short_name" => "CT",
  #       "types" => ["administrative_area_level_1", "political"]
  #     },
  #     %{
  #       "long_name" => "Spain",
  #       "short_name" => "ES",
  #       "types" => ["country", "political"]
  #     },
  #     %{
  #       "long_name" => "08005",
  #       "short_name" => "08005",
  #       "types" => ["postal_code"]
  #     }
  #   ],
  #   "formatted_address" => "Torre Mapfre, 08005 Barcelona, Spain",
  #   "geometry" => %{
  #     "bounds" => %{
  #       "northeast" => %{"lat" => 41.3884209, "lng" => 2.1982486},
  #       "southwest" => %{"lat" => 41.3874997, "lng" => 2.1970767}
  #     },
  #     "location" => %{"lat" => 41.387778, "lng" => 2.1975},
  #     "location_type" => "ROOFTOP",
  #     "viewport" => %{
  #       "northeast" => %{
  #         "lat" => 41.3893092802915,
  #         "lng" => 2.199011630291502
  #       },
  #       "southwest" => %{
  #         "lat" => 41.3866113197085,
  #         "lng" => 2.196313669708498
  #       }
  #     }
  #   },
  #   "place_id" => "ChIJVSrFXw6jpBIRjx7mjqEr1Ao",
  #   "types" => ["premise"]
  # }
  defp normalize(%{"results" => input, "status" => "OK"}), do: normalize(input)

  defp normalize(%{} = input) do
    with %{"lat" => lat, "lng" => lon} <- input["geometry"]["location"],
         %{
           "northeast" => %{"lat" => lat1, "lng" => lon1},
           "southwest" => %{"lat" => lat2, "lng" => lon2}
         } <- input["geometry"]["bounds"] || input["geometry"]["viewport"] do
      details =
        for %{"long_name" => name, "short_name" => _short_name, "types" => types} <-
              input["address_components"],
            type <- types,
            type != "political",
            do: {type, name},
            into: %{}

      output = %{
        details: LibLatLon.Utils.keywordize(details),
        bounds: [lat1, lat2, lon1, lon2],
        display: input["formatted_address"],
        lat: lat,
        lon: lon,
        meta:
          input
          |> Map.take(~w|types place_id licence|)
          |> LibLatLon.Utils.keywordize()
      }

      {:ok, output}
    else
      whatever -> {:error, whatever}
    end
  end

  defp normalize(list) when is_list(list), do: {:ok, normalize!(list)}

  defp normalize!([]), do: []
  defp normalize!(%{} = input), do: with({:ok, result} <- normalize(input), do: result)
  defp normalize!([%{} = h | t]), do: [normalize!(h) | normalize!(t)]

  defp smart_filter([%{} = input]), do: {:ok, input}

  defp smart_filter(input) do
    output =
      Enum.reduce(input, fn %{meta: %{types: elem_types}} = elem,
                            %{meta: %{types: acc_types}} = acc ->
        cond do
          Enum.member?(acc_types, "street_address") -> acc
          Enum.member?(elem_types, "street_address") -> elem
          Enum.member?(acc_types, "premise") -> acc
          Enum.member?(elem_types, "premise") -> elem
          true -> acc
        end
      end)

    {:ok, output}
  end

  defp do_lookup(query) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(query),
         {:ok, result} <- Jason.decode(body),
         {:ok, result} <- normalize(result),
         {:ok, result} <- smart_filter(result),
         {:ok, result} <- LibLatLon.Info.from_map(result) do
      {:ok, result}
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
