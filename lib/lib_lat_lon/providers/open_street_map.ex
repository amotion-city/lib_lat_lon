defmodule LibLatLon.Providers.OpenStreetMap do
  @moduledoc """
    `OpenStreetMap` provider implementation.
  """

  @server_url "https://nominatim.openstreetmap.org"
  @search Enum.join([@server_url, "search"], "/")
  @reverse Enum.join([@server_url, "reverse"], "/")

  @defaults %{ "accept-language": "en" }
  @reverse_defaults %{ format: :json, zoom: 16, addressdetails: 1 }
  @search_defaults %{ format: :json, polygon_geojson: 1, viewbox: "" }

  def name(), do: "Open Street Map"

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

  defp do_lookup(query) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(query),
         {:ok, result} <- Jason.decode(body) do
      result
    else # FIXME BETTER ERROR HANDLING
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, jason_error} ->
        {:error, jason_error}
    end
  end
end
