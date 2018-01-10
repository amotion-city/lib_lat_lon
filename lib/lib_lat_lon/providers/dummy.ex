defmodule LibLatLon.Providers.Dummy do
  @moduledoc """
    `OpenStreetMap` provider implementation.
  """

  @behaviour LibLatLon.Provider

  @infos ~w|test/inputs/dummy_info_41_2.lll|

  def name(), do: "Dummy (I’m used for tests)"

  def lookup(input, opts \\ %{})

  def lookup(%LibLatLon.Coords{}, _opts) do
    @infos
    |> Enum.random()
    |> File.read()
  end

  # # "https://nominatim.openstreetmap.org/search?format=json
  #             q=Barcelona+c%2Fde+Marina+16&polygon_geojson=1&viewbox=
  def lookup(<<_address :: binary>>, _opts) do
  end
end
