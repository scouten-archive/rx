defmodule Rx.Observable.FromEnumerable do
  @moduledoc false  # internal, implements Rx.Observable.from_enumerable/1

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:source, :started_by]

  # FIXME: Should use a streaming implementation.
  def init(_time, %__MODULE__{source: source, started_by: observer}), do:
    {:ok, observer, new_tasks: Enum.map(source, &schedule_notif/1)
                          ++ [{0, :send_done_notif}]}

  defp schedule_notif(value), do: {0, {:send_next_notif, value}}

  def handle_task(_time, {:send_next_notif, value}, observer), do:
    {:ok, observer, send: [{0, observer, {:next, [value]}}]}

  def handle_task(_time, :send_done_notif, observer), do:
    {:ok, observer, send: [{0, observer, :done}]}
end
