defmodule Rx.Observable.Empty do
  @moduledoc false  # internal, implements Rx.Observable.empty/0

  use Rx.Internal.ValidObservable
  use Rx.Schedulable  # TODO: Move to Rx.Observable.Stage?

  defstruct [:started_by]

  def init(_time, %__MODULE__{started_by: observer}), do:
    {:ok, observer, new_tasks: [{0, :send_done_notif}]}

  def handle_task(_time, :send_done_notif, observer), do:
    {:ok, observer, send: [{0, observer, :done}]}

  def terminate(_time, _reason, _state), do: :ok
end
