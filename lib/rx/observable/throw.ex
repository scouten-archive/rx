defmodule Rx.Observable.Throw do
  @moduledoc false  # internal

  use Rx.Internal.ValidObservable
  use Rx.Schedulable  # TODO: Move to Rx.Observable.Stage?

  defstruct [:error, :started_by]

  def init(_time, %__MODULE__{error: error, started_by: observer}), do:
    {:ok, observer, new_tasks: [{0, {:send_error_notif, error}}]}

  def handle_task(_time, {:send_error_notif, error}, observer), do:
    {:ok, observer, send: [{0, observer, {:error, error}}]}

  def terminate(_time, _reason, _state), do: :ok
end
