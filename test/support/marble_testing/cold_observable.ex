defmodule MarbleTesting.ColdObservable do
  @moduledoc false
  # using Rx.Observable.Stage  # TODO: Build this.
  defstruct [:events, :log_target_pid]

  def subscribe(time, %__MODULE__{events: events} = obs) do
    send(obs.log_target_pid, {:subscribed, time, obs})
    state = %{original_observable: obs}
    {:ok, state, new_events: Enum.map(events, &schedule_event/1)}
  end

  def unsubscribe(time, %{original_observable: obs} = state) do
    send(obs.log_target_pid, {:unsubscribed, time, obs})
    {:ok, state, []}
  end

  defp schedule_event({time, :next, value}), do: {time, &do_next_event/3, value}
  defp schedule_event({time, :done}), do: {time, &do_done_event/3, nil}

  defp do_next_event(_time, value, state), do: {:next, [value], state, []}
  defp do_done_event(_time, nil, state), do: {:done, state, []}
end
