defmodule Rx.Observable.Create do
  @moduledoc false  # internal, implements Rx.Observable.create/1

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:fun, :started_by]

  # FIXME: Naive implementation, blocks consuming process. Make better.
  @spec init(time :: number, args :: term) :: Rx.Schedulable.init_reply
  def init(_time, %__MODULE__{fun: fun, started_by: observer}) do
    pid = Process.spawn(__MODULE__, :wrap_user_fun, [fun, self()], [])
    {:ok, {observer, pid}, new_tasks: [{0, :relay_next_event}]}
  end

  @spec handle_task(time :: number, args :: term, state :: term) ::
    Rx.Schedulable.handle_task_reply
  def handle_task(time, task, observer)

  def handle_task(_time, :relay_next_event, {observer, pid}) do
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

  @spec terminate(time :: number, reason :: Rx.Schedulable.reason, state :: term) :: :ok
  def terminate(_time, _reason, {_observer, pid}) do
    Process.exit(pid, :shutdown)
    :ok
  end

  @spec wrap_user_fun(fun :: fun, observer_pid :: pid) :: :ok
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
