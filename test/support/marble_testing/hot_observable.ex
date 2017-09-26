defmodule MarbleTesting.HotObservable do
  @moduledoc false

  use Rx.Internal.ValidSubject
  use Rx.Schedulable

  # alias VirtualTimeScheduler, as: VTS

  defstruct [:notifs, :log_target_pid, :started_by]

  def init(%__MODULE__{notifs: _notifs} = _obs), do:
    raise "HotObservable not yet implemented"

  def handle_task({:send_next_notif, _value}, %{started_by: _observer} = _state), do:
    raise "HotObservable not yet implemented"
end
