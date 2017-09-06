defmodule Rx.Observable.Empty do
  @moduledoc false  # internal, implements Rx.Observable.empty/0

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:started_by]

  def init(%__MODULE__{started_by: observer}), do:
    {:ok, observer, new_tasks: [{0, :send_done_notif}]}

  def handle_task(:send_done_notif, observer), do:
    {:ok, observer, send: [{0, observer, :done}]}
end
