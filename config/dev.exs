use Mix.Config

config :lib_lat_lon, :decimal_precision, 4

config :lib_lat_lon, :provider, LibLatLon.Providers.GoogleMaps
config :lib_lat_lon, :google_maps_api_key, "AIzaSyALYWe8zFpxkbR410ERm2GaYDK6yUHSyA4"
