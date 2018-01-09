defmodule LibLatLon.Coords do
  alias LibLatLon.Coords

  @type t :: %__MODULE__{
    lat: number(),
    lon: number(),
    alt: number(),
    direction: number(),
    magnetic?: true | false
  }

  @image_start_marker 0xFFD8
  @fields ~w|lat lon alt direction magnetic?|a

  defstruct @fields

  @doc """
  Converts lat/lon between floats and
  `[degree,minute,second,semisphere]` representations.
  """
  @type dms :: {number(), number(), number()}
  @type dms_array :: [number()]
  @type dms_ss :: {dms() | dms_array(), binary() | nil}

  @spec borrow(dms(), any()) :: number()
  def borrow({d, m, s}, ss), do: borrow(d, m, s, ss)

  @spec borrow(dms_array(), any()) :: number()
  def borrow([d, m, s], ss), do: borrow(d, m, s, ss)

  @spec borrow(number(), number(), number(), any()) :: number()
  def borrow(d, m, s, ss \\ nil)
  def borrow(d, m, s, "S"), do: -do_borrow(d, m, s)
  def borrow(d, m, s, "W"), do: -do_borrow(d, m, s)
  def borrow(d, m, s, -1), do: -do_borrow(d, m, s)
  def borrow(d, m, s, _), do: do_borrow(d, m, s)

  @spec borrow(
          {number(), number()}
          | {dms_ss(), dms_ss()}
          | dms_ss()
          | [number()]
          | map()
          | binary()
          | Keyword.t()
          | %Exexif.Data.Gps{}
          | number()
        ) :: LibLatLon.Coords.t() | number()
  def borrow(lat_or_lon) when is_number(lat_or_lon), do: lat_or_lon

  def borrow({{d, m, s}, ss}), do: borrow(d, m, s, ss)
  def borrow({[d, m, s], ss}), do: borrow(d, m, s, ss)

  for id <- 1..2,
      im <- 1..2,
      is <- 1..2 do
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

  @doc """
      iex> LibLatLon.Coords.borrow("41°23´16˝N,2°11´50˝E")
      %LibLatLon.Coords{lat: 41.38777777777778, lon: 2.197222222222222}

      iex> LibLatLon.Coords.borrow({{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}})
      %LibLatLon.Coords{lat: 41.38777777777778, lon: 2.197222222222222}
  """
  def borrow(dmss) when is_binary(dmss) do
    dmss
    |> String.split([",", ";", " "])
    |> Enum.map(&borrow/1)
    |> borrow()
  end

  def borrow([lat, lon]), do: borrow({lat, lon})
  def borrow(%{lat: lat, lon: lon}), do: borrow({lat, lon})
  def borrow(%{latitude: lat, longitude: lon}), do: borrow({lat, lon})
  def borrow(latitude: lat, longitude: lon), do: borrow({lat, lon})

  def borrow(%Exexif.Data.Gps{
        gps_altitude: alt,
        gps_altitude_ref: alt_ref,
        gps_latitude: lat,
        gps_latitude_ref: lat_ref,
        gps_longitude: lon,
        gps_longitude_ref: lon_ref,
        gps_img_direction: dir,
        gps_img_direction_ref: dir_ref
      }) do
    with %LibLatLon.Coords{} = coords <- borrow({{lat, lat_ref}, {lon, lon_ref}}) do
      %LibLatLon.Coords{coords |
        alt: (if alt_ref == 0, do: alt, else: alt * alt_ref),
        direction: dir,
        magnetic?: dir_ref == "M"
      }
    end
  end

  def borrow({lat, lon}), do: %LibLatLon.Coords{lat: borrow(lat), lon: borrow(lon)}

  @spec do_borrow(number(), number(), number()) :: number()
  defp do_borrow(d, m, s), do: d + m / 60 + s / 3600

  ##############################################################################

  @doc """
      iex> LibLatLon.Coords.lend([41.38777777777778, 2.197222222222222])
      {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}
  """
  @spec lend(number(), number()) :: {dms_ss(), dms_ss()}
  def lend(dms1, dms2) when is_number(dms1) and is_number(dms2) do
    [dms1, dms2]
    |> Enum.with_index()
    |> Enum.map(&do_lend/1)
    |> List.to_tuple()
  end

  @spec lend({number(), number()}) :: {dms_ss(), dms_ss()}
  def lend({dms1, dms2}) when is_number(dms1) and is_number(dms2), do: lend(dms1, dms2)
  @spec lend([number()]) :: {dms_ss(), dms_ss()}
  def lend([dms1, dms2]) when is_number(dms1) and is_number(dms2), do: lend(dms1, dms2)
  @spec lend(Coords.t()) :: {dms_ss(), dms_ss()}
  def lend(%Coords{lat: dms1, lon: dms2}), do: lend(dms1, dms2)

  @spec do_lend({number(), 0 | 1}) :: dms_ss()
  def do_lend({dms, idx}) when is_number(dms) do
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

      iex> LibLatLon.Coords.coordinate!("test/inputs/1.jpg")
      #Coord<[lat: 41.37600333333334, lon: 2.1486783333333332, fancy: "41°22´33.612˝N,2°8´55.242˝E"]>

      iex> LibLatLon.Coords.coordinate("test/inputs/unknown.jpg")
      {:error, :illegal_source_file}
  """
  def coordinate(<<@image_start_marker::16, _::binary>> = buffer),
    do: with({:ok, info} <- Exexif.exif_from_jpeg_buffer(buffer), do: coordinate(info))

  def coordinate(file) when is_binary(file) do
    with true <- File.exists?(file) && !File.dir?(file),
         {:ok, info} <- Exexif.exif_from_jpeg_file(file) do
      coordinate(info)
    else
      false -> {:error, :illegal_source_file}
      whatever -> whatever
    end
  end

  def coordinate(nil), do: {:error, :no_gps_info}

  def coordinate(%{gps: %Exexif.Data.Gps{} = gps}), do: coordinate(gps)

  def coordinate(whatever), do: {:ok, Coords.borrow(whatever)}

  def coordinate!(whatever) do
    case coordinate(whatever) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, reason: inspect(reason)
    end
  end

  ##############################################################################

  defimpl String.Chars, for: LibLatLon.Coords do
    def to_string(term) do
      # {{{41, 23, 16.0}, "N"}, {{2, 11, 50.0}, "E"}}
      {{{d1, m1, s1}, ss1}, {{d2, m2, s2}, ss2}} = LibLatLon.Coords.lend(term)
      "#{d1}°#{m1}´#{s1}˝#{ss1},#{d2}°#{m2}´#{s2}˝#{ss2}"
    end
  end

  defimpl Inspect, for: LibLatLon.Coords do
    import Inspect.Algebra

    def inspect(%{lat: lat, lon: lon}, opts) do
      inner = [lat: lat, lon: lon, fancy: to_string(%LibLatLon.Coords{lat: lat, lon: lon})]
      concat(["#Coord<", to_doc(inner, opts), ">"])
    end
  end
end
