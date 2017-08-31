defmodule MarbleTesting.Observer do
  @moduledoc false

  use Rx.Observer

  defstruct [:source]

  def subscribe(_time, %__MODULE__{} = _), do: {:ok, []}

  def handle_events(time, values, acc) do
    new_notifs =
      values
      |> Enum.reverse()
      |> Enum.map(&({time, :next, &1}))

    {:ok, new_notifs ++ acc}
  end

  def handle_done(time, acc), do: {:ok, [{time, :done} | acc]}

  def handle_error(time, error, acc), do: {:ok, [{time, :error, error} | acc]}

  def unsubscribe(_time, _reason, acc), do: Enum.reverse(acc)
end
