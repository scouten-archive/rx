defmodule Rx.Observable.Create do
  @moduledoc false  # internal, implements Rx.Observable.create/1

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:fun, :started_by]

  # FIXME: Naive implementation, blocks consuming process. Make better.
  def init(%__MODULE__{fun: fun, started_by: observer}) do
    pid = Process.spawn(__MODULE__, :wrap_user_fun, [fun, self()], [])
    {:ok, {observer, pid}, new_tasks: [{0, :relay_next_event}]}
  end

  def handle_task(:relay_next_event, {observer, pid}) do
    receive do
      {:next, value} ->
        {:ok, {observer, pid}, send: [{0, observer, {:next, [value]}}],
                               new_tasks: [{1, :relay_next_event}]}
      :done ->
        {:ok, {observer, pid}, send: [{0, observer, :done}]}
      {:error, error} ->
        {:ok, {observer, pid}, send: [{0, observer, {:error, error}}]}
    after
      5000 ->
        {:ok, {observer, pid}, send: [{0, observer, {:error, :timeout}}]}
    end
  end

  def terminate(_reason, {_observer, pid}) do
    Process.exit(pid, :shutdown)
    :ok
  end

  def wrap_user_fun(fun, observer_pid) do
    next = fn value -> send(observer_pid, {:next, value}) end

    reason = try do
      fun.(next)
      :done
    rescue
      e in Rx.Error -> {:error, e.message}
      error -> {:error, error}
    end
    send(observer_pid, reason)
    :ok
  end
end
