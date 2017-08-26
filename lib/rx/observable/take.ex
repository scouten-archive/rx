defmodule Rx.Observable.Take do
  @moduledoc false  # internal, implements Rx.Observable.take/2

  use Rx.Internal.Operator

  defstruct [:source, :started_by, :n]

  def subscribe(_time, %__MODULE__{n: n}), do:
    {:ok, n}

  def handle_events(_time, events, n_remaining) when length(events) < n_remaining, do:
    {:events, events, n_remaining - length(events)}
  def handle_events(_time, events, n_remaining), do:
    {:done, Enum.take(events, n_remaining), 0}

  def handle_done(_time, state), do:
    {:done, [], state}

  def handle_error(_time, error, state), do:
    {:error, [], error, state}
end
