defmodule Rx.Observable.ToNotificationsStage do
  @moduledoc false  # internal, implements Rx.Observable.to_notifications

  use Rx.Internal.Operator

  defstruct [:source, :started_by]

  def handle_events(_time, events, state), do:
    {:events, Enum.map(events, &({:next, &1})), state}

  def handle_done(_time, state), do:
    {:done, [:done], state}

  def handle_error(_time, error, state), do:
    {:done, [{:error, error}], state}
end
