defmodule LibLatLon.MixProject do
  use Mix.Project

  def project do
    [
      app: :lib_lat_lon,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: ~w|logger httpoison|a,
      mod: {LibLatLon.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.0-rc1"},
      {:exexif, "~> 0.0"}

      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp description do
    """
    Small library for direct/reverse geocoding.

    Supports explicit latitude/longitude pairs, addresses as binaries,
      as well as jpeg/tiff images having a GPS information in exif.
    """
  end

  defp package do
    [
      name: :lib_lat_lon,
      files: ~w|lib mix.exs README.md|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/amotion-city/lib_lat_lon",
        "Docs" => "https://hexdocs.pm/lib_lat_lon"
      }
    ]
  end
end
