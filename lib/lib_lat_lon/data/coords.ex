defmodule LibLatLon.Coords do
  @type t :: %__MODULE__{lat: float(), lon: float(), alt: float()}

  @fields ~w|lat lon alt|a

  defstruct @fields
end

