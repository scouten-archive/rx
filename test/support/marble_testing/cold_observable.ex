defmodule MarbleTesting.ColdObservable do
  @moduledoc false

  use Rx.Internal.ValidObservable
  use Rx.Schedulable

  defstruct [:notifs, :log_target_pid, :started_by]

  def init(time, %__MODULE__{notifs: notifs} = obs) do
    send(obs.log_target_pid, {:subscribed, time, Map.put(obs, :started_by, nil)})
    {:ok, obs, new_tasks: Enum.map(notifs, &schedule_notif/1)}
  end

  defp schedule_notif({time, :next, value}), do: {time, {:send_next_notif, value}}
  defp schedule_notif({time, :error, error}), do: {time, {:send_error_notif, error}}
  defp schedule_notif({time, :done}), do: {time, :send_done_notif}

  def handle_task(_time, {:send_next_notif, value}, %{started_by: observer} = state), do:
    {:ok, state, send: [{0, observer, {:next, [value]}}]}

  def handle_task(_time, {:send_error_notif, error}, %{started_by: observer} = state), do:
    {:ok, state, send: [{0, observer, {:error, error}}]}

  def handle_task(_time, :send_done_notif, %{started_by: observer} = state), do:
    {:ok, state, send: [{0, observer, :done}]}

  def terminate(time, _reason, %__MODULE__{log_target_pid: pid} = obs) do
    send(pid, {:unsubscribed, time, Map.put(obs, :started_by, nil)})
    :ok
  end
end
