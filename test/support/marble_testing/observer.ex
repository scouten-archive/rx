defmodule MarbleTesting.Observer do
  @moduledoc false

  use Rx.Observer

  alias VirtualTimeScheduler, as: VTS

  defstruct [:source]

  def subscribe(%__MODULE__{} = _), do: {:ok, []}

  def handle_events(values, acc) do
    time = VTS.time_now()

    new_notifs =
      values
      |> Enum.reverse()
      |> Enum.map(&({time, :next, &1}))

    {:ok, new_notifs ++ acc}
  end

  def handle_done(acc), do: {:ok, [{VTS.time_now(), :done} | acc]}

  def handle_error(error, acc), do: {:ok, [{VTS.time_now(), :error, error} | acc]}

  def unsubscribe(_reason, acc), do: Enum.reverse(acc)
end
