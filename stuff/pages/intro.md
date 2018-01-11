# LibLatLon

**{:ok, 📍}** |> handy library for managing geo coordinates that
includes _direct/reverse geocoding_ features.

## Installation

```elixir
def deps do
  [
    {:lib_lat_lon, "~> 0.1"}
  ]
end
```

### Usage

#### Reverse lookup

```elixir
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
```

#### Direct lookup, using `GoogleMaps`

```elixir
LibLatLon.lookup(
  "Av. del Litoral, 28, 08005 Barcelona, Spain",
  LibLatLon.Providers.GoogleMaps)

%LibLatLon.Info{
  address: "Av. del Litoral, 28, 08005 Barcelona, Spain",
  bounds: %LibLatLon.Bounds{
    from: #Coord<[
      lat: 41.3893258802915,
      lon: 2.198497180291502,
      fancy: "41°23´21.57316905˝N,2°11´54.58984905˝E"
    ]>,
    to: #Coord<[
      lat: 41.3866279197085,
      lon: 2.195799219708499,
      fancy: "41°23´11.86051095˝N,2°11´44.87719095˝E"
    ]>
  },
  coords: #Coord<[
    lat: 41.3879769,
    lon: 2.1971482,
    fancy: "41°23´16.71684˝N,2°11´49.73352˝E"
  ]>,
  details: %{
    administrative_area_level_1: "Catalunya",
    administrative_area_level_2: "Barcelona",
    country: "Spain",
    locality: "Barcelona",
    postal_code: "08005",
    route: "Avinguda del Litoral",
    street_number: "28"
  },
  meta: %{place_id: "ChIJB801WA6jpBIRLvQ6BHMtKB4", types: ["street_address"]}
}
```

### Currently supported providers

* [GoogleMaps](https://developers.google.com/maps/documentation/geocoding/intro#geocoding);
* [OpenStreetMaps](https://nominatim.openstreetmap.org/).

### Currently supported sources

* latitude/longitude pair in any form (e.g. `{lat, lon}` tuple);
* an address as a `binary()`;
* a `jpeg` image with `gps` information.

#### Notes about `GoogleMaps`

To use `LibLatLon.Providers.GoogleMaps` provider, go
[get API key](https://developers.google.com/maps/documentation/geocoding/get-api-key)
from Google and put the following lines into your `config.exs` file:

```elixir
config :lib_lat_lon, :provider, LibLatLon.Providers.GoogleMaps
config :lib_lat_lon, :google_maps_api_key, "YOUR_GOOGLE_API_KEY"
```

or, alternatively, use the system environment variable `GOOGLE_MAPS_API_KEY`.

### Docs / Changelog

Documentation can be found at [https://hexdocs.pm/lib_lat_lon](https://hexdocs.pm/lib_lat_lon).
