defmodule LibLatLon do
  @moduledoc """
  This module is basically the only module consumers of this library
    should be interested in.

  There is a single function exported: [`LibLatLon.lookup/3`].
  """

  @default_provider Application.get_env(
                      :lib_lat_lon,
                      :provider,
                      LibLatLon.Providers.OpenStreetMap
                    )

  @doc """
  Pass anything to lookup using default provider and with default options.
  Pass a provider as the second argument to use a specific provider.
  Pass options map like `%{language: "es"}` as a last parameter to
    tune the provider’s response. _NB:_ options are provider-specific.

  ## Examples

      iex> LibLatLon.lookup(
      ...>   {42, 3.14159265},
      ...>   LibLatLon.Providers.Dummy,
      ...>   %{extended: true}).details
      %{
        city: "Barcelona",
        city_district: "Sant Martí",
        country: "España",
        country_code: "es",
        county: "BCN",
        postcode: "08020",
        road: "Avinguda del Litoral",
        state: "CAT",
        suburb: "la Vila Olímpica del Poblenou"
      }

  """
  @spec lookup(any(), atom(), %{}) :: {:ok, LibLatLon.Info.t()} | {:error, any()}
  def lookup(value, provider \\ @default_provider, opts \\ %{}) do
    case guess_lookup(provider, value, opts) do
      {:ok, result} -> result
      anything -> anything
    end
  end

  ##############################################################################

  defp guess_lookup(provider, any, opts) do
    lookup_arg =
      case LibLatLon.Coords.coordinate(any) do
        {:ok, %LibLatLon.Coords{} = result} -> result
        _ -> inspect(any)
      end

    provider.lookup(lookup_arg, opts)
  end

  ##############################################################################

  defmodule Utils do
    @moduledoc false

    @spec safe_float(binary() | number()) :: float()
    def safe_float(v) when is_float(v), do: v
    def safe_float(v) when is_integer(v), do: v * 1.0

    def safe_float(v) when is_binary(v) do
      case Float.parse(v) do
        {float, ""} -> float
        {float, _} -> float
        :error -> 0.0
      end
    end

    @spec strict_float(binary() | number()) :: float() | nil
    def strict_float(v) when is_float(v), do: v
    def strict_float(v) when is_integer(v), do: v * 1.0

    def strict_float(v) when is_binary(v) do
      case Float.parse(v) do
        {float, ""} -> float
        {_float, _non_empty} -> nil
        :error -> nil
      end
    end

    @spec keywordize(map() | nil) :: map()
    def keywordize(nil), do: nil

    def keywordize(%{} = map) do
      map
      |> Enum.map(fn
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
        {k, v} when is_atom(k) -> {k, v}
        {k, v} -> {k |> inspect() |> String.to_atom(), v}
      end)
      |> Enum.into(%{})
    end
  end
end
