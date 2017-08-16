defmodule VirtualTimeScheduler do
  @moduledoc false  # Only used in testing infrastructure.

  defstruct pending_events: [], seq: 0, acc: nil

  def new(acc), do: %__MODULE__{acc: acc}

  def schedule(%__MODULE__{pending_events: old_events, seq: seq} = v,
               time, fun, args)
  when is_integer(time) and time >= 0 and is_function(fun, 3)
  do
    new_event = {time, seq + 1, fun, args}
    new_events = Enum.sort([new_event | old_events])
    %{v | pending_events: new_events, seq: seq + 1}
  end

  def run(%__MODULE__{pending_events: [], acc: acc}), do: acc

  def run(%__MODULE__{pending_events: [{time, _s, fun, args} | remaining_events],
                      seq: _seq, acc: acc} = v)
  do
    {new_acc, new_events} = fun.(time, args, acc)
    new_events = validate_events(new_events)

    v = %{v | pending_events: remaining_events, acc: new_acc}

    v = Enum.reduce(new_events, v, fn({time_delta, fun, arg}, acc) ->
      schedule(acc, time + time_delta, fun, arg)
    end)

    run(v)
  end

  defp validate_events(events) do
    unless Enum.all?(events, &validate_event/1), do:
      raise ArgumentError, "invalid event passed to VTS run callback\n#{inspect events}"

    events
  end

  defp validate_event({time, fun, _arg})
    when is_integer(time) and time >= 0 and is_function(fun, 3)
  do
    true
  end
  defp validate_event(_), do: false
end
