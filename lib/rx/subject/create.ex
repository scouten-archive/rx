defmodule Rx.Subject.Create do
  @moduledoc false  # internal, implements Rx.Subject.create/0

  use Rx.Internal.ValidSubject
  use Rx.Schedulable

  defstruct [:pid, :ref, :started_by]

  # FIXME: Naive implementation, requires events to be sent ahead of time. Make better.
  # Also, only supports one observer.
  def init(%__MODULE__{ref: ref, started_by: observer}) do
    {:ok, {observer, ref}, new_tasks: [{0, :relay_next_event}]}
  end

  def handle_task(:relay_next_event, {observer, ref}) do
    receive do
      {:next, ^ref, value} ->
        {:ok, {observer, ref}, send: [{0, observer, {:next, [value]}}],
                               new_tasks: [{1, :relay_next_event}]}
      {:done, ^ref} ->
        {:ok, {observer, ref}, send: [{0, observer, :done}]}
      {:error, ^ref, error} ->
        {:ok, {observer, ref}, send: [{0, observer, {:error, error}}]}
    after
      5000 ->
        {:ok, {observer, ref}, send: [{0, observer, {:error, :timeout}}]}
    end
  end
end
