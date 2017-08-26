defmodule Rx.Observable.Empty do
  @moduledoc false  # internal, implements Rx.Observable.empty/0

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:started_by]

  @spec init(time :: number, args :: term) :: Rx.Schedulable.init_reply
  def init(_time, %__MODULE__{started_by: observer}), do:
    {:ok, observer, new_tasks: [{0, :send_done_notif}]}

  @spec handle_task(time :: number, args :: term, state :: term) ::
    Rx.Schedulable.handle_task_reply
  def handle_task(_time, :send_done_notif, observer), do:
    {:ok, observer, send: [{0, observer, :done}]}
end
