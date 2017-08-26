defmodule Rx.Observable.ToNotifications do
  @moduledoc false  # internal, implements Rx.Observable.to_notifications/1

  use Rx.Internal.Operator

  defstruct [:source, :started_by]

  @spec handle_events(time :: non_neg_integer, events :: [term], state :: term) ::
    Rx.Internal.Operator.handle_events_reply
  def handle_events(_time, events, state), do:
    {:events, Enum.map(events, &({:next, &1})), state}

  @spec handle_done(time :: non_neg_integer, state :: term) ::
    Rx.Internal.Operator.handle_events_reply
  def handle_done(_time, state), do:
    {:done, [:done], state}

  @spec handle_error(time :: non_neg_integer, error :: term, state :: term) ::
    Rx.Internal.Operator.handle_events_reply
  def handle_error(_time, error, state), do:
    {:done, [{:error, error}], state}
end
