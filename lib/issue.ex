defmodule LibLatLon.Issue do
  @moduledoc false

  defexception ~w|message reason bag|a

  @default_reason :unknown

  @type t :: %__MODULE__{
          message: String.t(),
          reason: atom(),
          bag: keyword()
        }

  @spec exception(keyword() | String.t()) :: Exception.t()
  def exception(reason: reason),
    do: exception(reason: reason, bag: [])

  def exception(reason: reason, bag: bag) do
    message = "Geo issue happened. Reason: #{reason}."
    exception(message, reason: reason, bag: bag)
  end

  def exception(message) when is_binary(message),
    do: exception(message, [])

  @spec exception(String.t(), keyword() | map()) :: Exception.t()
  def exception(message, %{} = bag) when is_binary(message),
    do: exception(message, Map.to_list(bag))

  def exception(message, bag) when is_binary(message) and is_list(bag) do
    bag = Keyword.delete(bag, :reason)

    %LibLatLon.Issue{
      message: message,
      reason: Keyword.get(bag, :reason, @default_reason),
      bag: bag[:bag] || bag
    }
  end
end
