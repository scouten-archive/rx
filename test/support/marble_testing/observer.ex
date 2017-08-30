defmodule MarbleTesting.Observer do
  @moduledoc false

  use Rx.Observer

  import Rx.Internal.ValidObservable

  defstruct [:observable]

  def subscribe(_time, %__MODULE__{observable: source} = _), do:
    {:ok, [], start: [{0, :marble_source, enforce(source)}]}
    # TODO: In the specific case of MT.Observer, how to handle the
    # case where the source (Subject) gets created first and then
    # we need to subscribe to it later.

  def handle_events(time, values, acc) do
    new_notifs =
      values
      |> Enum.reverse()
      |> Enum.map(&({time, :next, &1}))

    {:ok, new_notifs ++ acc}
  end

  def handle_done(time, acc), do:
    {:ok, [{time, :done} | acc], stop: [{:marble_source, :done}]}

  def handle_error(time, error, acc), do:
    {:ok, [{time, :error, error} | acc], stop: [{:marble_source, :done}]}

  def unsubscribe(_time, _reason, acc), do: Enum.reverse(acc)
end
