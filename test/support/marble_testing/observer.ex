defmodule MarbleTesting.Observer do
  # credo:disable-for-this-file Credo.Check.Readability.Specs

  @moduledoc false

  use Rx.Schedulable

  defstruct [:observable]

  def init(_time, %__MODULE__{observable: source} = _), do:
    {:ok, [], start: [{0, :marble_source, source}]}

  def handle_task(time, {:next, values}, acc) do
    new_notifs =
      values
      |> Enum.reverse()
      |> Enum.map(&({time, :next, &1}))

    {:ok, new_notifs ++ acc}
  end

  def handle_task(time, :done, acc), do:
    {:ok, [{time, :done} | acc], stop: [{:marble_source, :done}]}

  def terminate(_time, _reason, acc), do: Enum.reverse(acc)
end
