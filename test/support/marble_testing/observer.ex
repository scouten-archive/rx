defmodule MarbleTesting.Observer do
  @moduledoc false

  use Rx.Observer

  alias VirtualTimeScheduler, as: VTS

  defstruct [:source]

  def subscribe(_time, %__MODULE__{} = _), do: {:ok, []}

  def handle_events(_time, values, acc) do
    time = VTS.time_now()

    new_notifs =
      values
      |> Enum.reverse()
      |> Enum.map(&({time, :next, &1}))

    {:ok, new_notifs ++ acc}
  end

  def handle_done(_time, acc), do: {:ok, [{VTS.time_now(), :done} | acc]}

  def handle_error(_time, error, acc), do: {:ok, [{VTS.time_now(), :error, error} | acc]}

  def unsubscribe(_time, _reason, acc), do: Enum.reverse(acc)
end
