defmodule LibLatLon.Providers.OpenStreetMap do
  @moduledoc """
    `OpenStreetMap` provider implementation.
  """

  @server_url "https://nominatim.openstreetmap.org"
  @search Enum.join([@server_url, "search"], "/")
  @reverse Enum.join([@server_url, "reverse.php"], "/")

  @defaults %{
    format: :json,
    zoom: 16,
    addressdetails: 1
  }

  def name(), do: "Open Street Map"

  # "https://nominatim.openstreetmap.org/reverse?format=json&
  #           accept-language={{ language }}&lat={{ latitude }}&
  #           lon={{ longitude }}&zoom={{ zoom }}&addressdetails=1"
  def lookup(%LibLatLon.Coords{lat: lat, lon: lon}, opts \\ @defaults) do
    query = 
      opts
      |> Map.merge(%{lat: lat, lon: lon})
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")
    
    case HTTPoison.get(Enum.join([@reverse, query], "?")) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end
    
  end