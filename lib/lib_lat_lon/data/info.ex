defmodule LibLatLon.Info do
  @type t :: %__MODULE__{
    coords: LibLatLon.Coords.t(),
    address: binary()
  }

  @fields ~w|coords address|a

  defstruct @fields
end
