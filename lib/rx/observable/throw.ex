defmodule Rx.Observable.Throw do
  @moduledoc false  # internal, implements Rx.Observable.throw/1

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:error, :started_by]

  @spec init(time :: number, args :: term) :: Rx.Schedulable.init_reply
  def init(_time, %__MODULE__{error: error, started_by: observer}), do:
    {:ok, observer, new_tasks: [{0, {:send_error_notif, error}}]}

  @spec handle_task(time :: number, args :: term, state :: term) ::
    Rx.Schedulable.handle_task_reply
  def handle_task(_time, {:send_error_notif, error}, observer), do:
    {:ok, observer, send: [{0, observer, {:error, error}}]}
end
