defmodule LibLatLon.Coords.Test do
  use ExUnit.Case
  doctest LibLatLon.Coords

  test "from_exif_gps" do
    info = LibLatLon.lookup({42, 3.14159265})
    assert %LibLatLon.Info{} = info

    assert info.address ==
             "GIV-6501, Fontanilles, Baix Empordà, Girona, Catalunya, 17256, España"
  end
end
