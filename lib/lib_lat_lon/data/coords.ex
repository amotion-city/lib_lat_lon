defmodule LibLatLon.Coords do
  @moduledoc """
  Main struct to be used as coordinates representation.

  One might cast nearly everything to `LibLatLon.Coord` with
  `LibLatLon.Coord.borrow/1` and/or `LibLatLon.Coord.borrow/2`.

  This struct implements both `String.Chars` and `Inspect` protocols.
  The fancy string representation of any lat/lon pair might be get by
  `Kernel.to_string/1`:

      iex> to_string(LibLatLon.Coords.borrow(lat: 41.38, lon: 2.19))
      "41°22´48.0˝N,2°11´24.0˝E"

  Note, that this representation might be used as is when querying any
  geolocation services and/or `GoogleMaps`. Try:

  * http://maps.google.com?search=41°22´48.0˝N,2°11´24.0˝E
  """

  case Code.ensure_compiled(Exexif) do
    {:module, Exexif} ->
      :ok

    {:error, reason} ->
      raise ArgumentError,
            "could not load module #{inspect(Exexif)} due to reason #{inspect(reason)}"
  end

  alias LibLatLon.Coords

  @typedoc """
  The type to store coordinates.

  Mostly used fields are `lat` and `lon`, stored as `Float.t`. Also
  might contain `altitude` and `direction` to calculate the latitude
  and langitude for the destination point (mostly used when dealing with
  `EXIF` information from images.)
  """
  @type t :: %{
          __struct__: __MODULE__,
          lat: number(),
          lon: number(),
          alt: number(),
          direction: number(),
          magnetic?: boolean()
        }

  @decimal_precision Application.compile_env(:lib_lat_lon, :decimal_precision, 9)

  @image_start_marker 0xFFD8
  @fields ~w|lat lon alt direction magnetic?|a

  defstruct @fields

  @typedoc "Degrees, minutes and seconds as a tuple"
  @type dms :: {number(), number(), number()}
  @typedoc "Degrees, minutes and seconds as a list"
  @type dms_list :: [number()]
  @typedoc "Degrees, minutes and seconds with an optional semisphere reference"
  @type dms_ss :: {dms() | dms_list(), binary() | nil}

  @doc """
  Converts `{{degree, minute, second}, semisphere}` or
    `{[degree, minute, second], semisphere}` representation into
    `LibLatLon.Coords`.
  """
  @spec borrow(dms() | dms_list(), any()) :: number()
  def borrow({d, m, s}, ss), do: borrow(d, m, s, ss)
  def borrow([d, m, s], ss), do: borrow(d, m, s, ss)

  @doc """
  Converts `degree, minute, second, semisphere` representation into
    `LibLatLon.Coords`. When the last parameter `semisphere` is not one of:
    `"S"` or `"W"` or `-1` or `:south` or `west`, it is implicitly
    considered to be in `NE` semisphere.
  """
  @spec borrow(number(), number(), number(), any()) :: number()
  def borrow(d, m, s, ss \\ nil)
  def borrow(d, m, s, "S"), do: -do_borrow(d, m, s)
  def borrow(d, m, s, :south), do: -do_borrow(d, m, s)
  def borrow(d, m, s, "W"), do: -do_borrow(d, m, s)
  def borrow(d, m, s, :west), do: -do_borrow(d, m, s)
  def borrow(d, m, s, -1), do: -do_borrow(d, m, s)
  def borrow(d, m, s, _), do: do_borrow(d, m, s)

  @doc """
  Converts literally any input to `LibLatLon.Coords` instance.

  ## Examples

      iex> LibLatLon.Coords.borrow("41°23´16˝N,2°11´50˝E")
      %LibLatLon.Coords{lat: 41.38777777777778, lon: 2.197222222222222}

      iex> LibLatLon.Coords.borrow("41°23´16.222˝N,2°11´50.333˝E")
      %LibLatLon.Coords{lat: 41.387839444444445, lon: 2.197314722222222}

      iex> LibLatLon.Coords.borrow({{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}})
      %LibLatLon.Coords{lat: 41.38777777777778, lon: 2.197222222222222}

      iex> LibLatLon.Coords.borrow(lat: 41.38, lon: 2.19)
      %LibLatLon.Coords{lat: 41.38, lon: 2.19}
  """
  @spec borrow(
          {number(), number()}
          | nil
          | {dms_ss(), dms_ss()}
          | dms_ss()
          | [number()]
          | map()
          | binary()
          | keyword()
          | %Exexif.Data.Gps{}
        ) :: LibLatLon.Coords.t() | number() | nil | {:error, any()}

  def borrow(nil), do: nil
  def borrow([nil, _]), do: nil
  def borrow([_, nil]), do: nil
  def borrow({nil, _}), do: nil
  def borrow({_, nil}), do: nil

  def borrow(lat_or_lon) when is_number(lat_or_lon), do: lat_or_lon
  def borrow([lat_or_lon]) when is_number(lat_or_lon), do: lat_or_lon

  def borrow({{d, m, s}, ss}), do: borrow(d, m, s, ss)
  def borrow({[d, m, s], ss}), do: borrow(d, m, s, ss)

  for id <- 1..2,
      im <- 1..2,
      is <- 1..@decimal_precision do
    for jd <- 1..2,
        jm <- 1..2,
        js <- 1..@decimal_precision do
      def borrow(<<
            d1::binary-size(unquote(id)),
            "°",
            m1::binary-size(unquote(im)),
            "´",
            s1::binary-size(unquote(is)),
            "˝",
            ss1::binary-size(1),
            _::binary-size(1),
            d2::binary-size(unquote(jd)),
            "°",
            m2::binary-size(unquote(jm)),
            "´",
            s2::binary-size(unquote(js)),
            "˝",
            ss2::binary-size(1)
          >>) do
        [dms1, dms2] =
          Enum.map(
            [[d1, m1, s1], [d2, m2, s2]],
            &Enum.map(&1, fn v -> with {v, ""} <- Float.parse(v), do: v end)
          )

        borrow({{dms1, ss1}, {dms2, ss2}})
      end
    end

    def borrow(<<
          d::binary-size(unquote(id)),
          "°",
          m::binary-size(unquote(im)),
          "´",
          s::binary-size(unquote(is)),
          "˝",
          ss::binary-size(1)
        >>) do
      [d, m, s]
      |> Enum.map(fn v -> with {v, ""} <- Float.parse(v), do: v end)
      |> borrow(ss)
    end
  end

  def borrow(dmss) when is_binary(dmss) do
    dmss
    |> String.split([",", ";", " "])
    |> Enum.map(&LibLatLon.Utils.strict_float/1)
    |> Enum.map(&borrow/1)
    |> borrow()
  end

  def borrow(latitude: lat, longitude: lon), do: borrow({lat, lon})
  def borrow(lat: lat, lon: lon), do: borrow({lat, lon})
  def borrow([lat, lon]), do: borrow({lat, lon})
  def borrow(%{lat: lat, lon: lon}), do: borrow({lat, lon})
  def borrow(%{latitude: lat, longitude: lon}), do: borrow({lat, lon})

  def borrow(%Exexif.Data.Gps{
        gps_altitude: alt,
        gps_altitude_ref: alt_ref,
        gps_latitude: lat,
        gps_latitude_ref: lat_ref,
        gps_longitude: lon,
        gps_longitude_ref: lon_ref,
        gps_img_direction: dir,
        gps_img_direction_ref: dir_ref
      })
      when not is_nil(alt) and not is_nil(alt_ref) do
    with %LibLatLon.Coords{} = coords <- borrow({{lat, lat_ref}, {lon, lon_ref}}) do
      %LibLatLon.Coords{
        coords
        | alt: if(alt_ref == 0, do: alt, else: alt * alt_ref),
          direction: dir,
          magnetic?: dir_ref == "M"
      }
    end
  end

  def borrow(%Exexif.Data.Gps{
        gps_latitude: lat,
        gps_latitude_ref: lat_ref,
        gps_longitude: lon,
        gps_longitude_ref: lon_ref,
        gps_img_direction: dir,
        gps_img_direction_ref: dir_ref
      }) do
    with %LibLatLon.Coords{} = coords <- borrow({{lat, lat_ref}, {lon, lon_ref}}) do
      %LibLatLon.Coords{
        coords
        | direction: dir,
          magnetic?: dir_ref == "M"
      }
    end
  end

  def borrow({lat, lon}), do: %LibLatLon.Coords{lat: borrow(lat), lon: borrow(lon)}
  def borrow(shit), do: {:error, {:weird_input, shit}}

  @spec do_borrow(number(), number(), number()) :: number()
  defp do_borrow(d, m, s), do: d + m / 60 + s / 3600

  ##############################################################################

  @doc """
  Converts literally anything, provided as latitude _and_ longitude values
    to two tuples `{{degree, minute, second}, semisphere}`. Barely used
    from the outside the package, since `LibLatLon.Coords.t` is obviously
    better type to work with coordinates by all means.

  ## Examples

      iex> LibLatLon.Coords.lend(41.38777777777778, 2.197222222222222)
      {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}
  """
  @spec lend(number(), number()) :: {dms_ss(), dms_ss()}
  def lend(dms1, dms2) when is_number(dms1) and is_number(dms2) do
    [dms1, dms2]
    |> Enum.with_index()
    |> Enum.map(&do_lend/1)
    |> List.to_tuple()
  end

  @doc """
  Converts literally anything, provided as combined `latlon` value
    to two tuples `{{degree, minute, second}, semisphere}`. Barely used
    from the outside the package, since `LibLatLon.Coords.t` is obviously
    better type to work with coordinates by all means.

  ## Examples

      iex> LibLatLon.Coords.lend({41.38777777777778, 2.197222222222222})
      {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}

      iex> LibLatLon.Coords.lend([41.38777777777778, 2.197222222222222])
      {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}
  """
  @spec lend({number(), number()} | [number()] | LibLatLon.Coords.t()) :: {dms_ss(), dms_ss()}
  def lend({dms1, dms2}) when is_number(dms1) and is_number(dms2), do: lend(dms1, dms2)
  def lend([dms1, dms2]) when is_number(dms1) and is_number(dms2), do: lend(dms1, dms2)
  def lend(%Coords{lat: dms1, lon: dms2}), do: lend(dms1, dms2)

  @spec do_lend({number(), 0 | 1}) :: dms_ss()
  defp do_lend({dms, idx}) when is_number(dms) do
    ss = dms > 0
    abs = if ss, do: dms, else: -dms
    d = abs |> Float.floor() |> Kernel.round()
    m = abs |> Kernel.-(d) |> Kernel.*(60.0) |> Float.floor() |> Kernel.round()
    s = abs |> Kernel.-(d) |> Kernel.-(m / 60.0) |> Kernel.*(3600.0) |> Float.round(8)

    ss =
      case {ss, idx} do
        {true, 0} -> "N"
        {true, _} -> "E"
        {_, 0} -> "S"
        {_, _} -> "W"
      end

    {{d, m, s}, ss}
  end

  @doc """
  Retrieves coordinates from barely anything.

      iex> {:ok, result} = LibLatLon.Coords.coordinate("test/inputs/1.jpg")
      ...> result
      #Coord<[lat: 41.37600333333334, lon: 2.1486783333333332, fancy: "41°22´33.612˝N,2°8´55.242˝E"]>

      iex> LibLatLon.Coords.coordinate("test/inputs/unknown.jpg")
      {:error, {:weird_input, [nil]}}
  """
  @spec coordinate(nil | binary() | %{} | any()) :: {:ok, LibLatLon.Coords.t()} | {:error, any()}
  def coordinate(<<@image_start_marker::16, _::binary>> = buffer),
    do: with({:ok, info} <- Exexif.exif_from_jpeg_buffer(buffer), do: coordinate(info))

  def coordinate(file) when is_binary(file) do
    with true <- File.exists?(file) && !File.dir?(file),
         {:ok, info} <- Exexif.exif_from_jpeg_file(file) do
      coordinate(info)
    else
      false ->
        case borrow(file) do
          {:error, anything} -> {:error, anything}
          result -> {:ok, result}
        end

      whatever ->
        {:error, {:illegal_source_file, whatever}}
    end
  end

  def coordinate(nil), do: {:error, :no_gps_info}

  def coordinate(%{gps: %Exexif.Data.Gps{} = gps}), do: coordinate(gps)

  def coordinate(whatever) do
    case borrow(whatever) do
      %LibLatLon.Coords{} = coords -> {:ok, coords}
      {:error, reason} -> {:error, reason}
      whatever -> {:error, {:malformed, whatever}}
    end
  end

  @doc """
  Same as `LibLatLon.Coords.coordinate/1`, but banged.

  ## Examples

      iex> LibLatLon.Coords.coordinate!("test/inputs/1.jpg")
      #Coord<[lat: 41.37600333333334, lon: 2.1486783333333332, fancy: "41°22´33.612˝N,2°8´55.242˝E"]>
  """
  @spec coordinate!(nil | binary() | %{} | any()) :: LibLatLon.Coords.t() | no_return()
  def coordinate!(whatever) do
    case coordinate(whatever) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, message: "Reason: #{inspect(reason)}"
    end
  end

  ##############################################################################

  defimpl String.Chars, for: LibLatLon.Coords do
    @doc "Returns a fancy representation of coordinates, like “41°22´33.612˝N,2°8´55.242˝E”"
    def to_string(term) do
      # {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}
      {{{d1, m1, s1}, ss1}, {{d2, m2, s2}, ss2}} = LibLatLon.Coords.lend(term)
      "#{d1}°#{m1}´#{s1}˝#{ss1},#{d2}°#{m2}´#{s2}˝#{ss2}"
    end
  end

  defimpl Inspect, for: LibLatLon.Coords do
    import Inspect.Algebra

    @doc ~S"""
    Returns a `doc`, containing the latitude, the longiture,
      and the fancy representation of coordinates, like “41°22´33.612˝N,2°8´55.242˝E”
    """
    def inspect(%{lat: lat, lon: lon}, opts) do
      inner = [lat: lat, lon: lon, fancy: to_string(%LibLatLon.Coords{lat: lat, lon: lon})]
      concat(["#Coord<", to_doc(inner, opts), ">"])
    end
  end
end
