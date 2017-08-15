defmodule VirtualTimeScheduler do
  @moduledoc false  # Only used in testing infrastructure.

  defstruct time: 0, pending_events: [], seq: 0

  def new, do: %__MODULE__{}

  def schedule(%__MODULE__{time: time_now, pending_events: old_events, seq: seq} = v,
               time_delta, fun, args)
  when time_delta >= 0 and is_function(fun, 2)
  do
    sched_time = time_now + time_delta
    new_event = {sched_time, seq + 1, fun, args}
    new_events = Enum.sort([new_event | old_events])
    %{v | pending_events: new_events, seq: seq + 1}
  end

  def flush(%__MODULE__{pending_events: events} = _v) do
    Enum.each(events, fn({time, _seq, fun, args}) ->
      fun.(time, args)
    end)
  end
end
