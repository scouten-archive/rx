defmodule Rx.Observable.ToNotifications do
  @moduledoc false  # internal, implements Rx.Observable.to_notifications/1

  use Rx.Internal.Operator

  defstruct [:source, :started_by]

  def handle_events(events, state), do:
    {:events, Enum.map(events, &({:next, &1})), state}

  def handle_done(state), do:
    {:done, [:done], state}

  def handle_error(error, state), do:
    {:done, [{:error, error}], state}
end
