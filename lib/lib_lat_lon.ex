defmodule LibLatLon do
  @moduledoc """
  Documentation for LibLatLon.
  """

  @default_provider Application.get_env(
    :lib_lat_lon, :provider, LibLatLon.Providers.OpenStreetMap)

  @doc """
  Hello world.

  ## Examples

  iiex> LibLatLon.lookup()
  :world

  """
  def lookup(value, provider \\ @default_provider, opts \\ %{}) do
    guess_lookup(provider, value, opts)
  end

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
      Enum.map(map, fn
        {k, v} when is_binary(k) -> {String.to_atom(k), v}
        {k, v} when is_atom(k) -> {k, v}
        {k, v} -> {k |> inspect() |> String.to_atom(), v}
      end)
      |> Enum.into(%{})
    end

  end
end
