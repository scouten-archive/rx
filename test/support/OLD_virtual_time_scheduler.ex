defmodule OLD.VirtualTimeScheduler do
  @moduledoc false  # Only used in testing infrastructure.

  def run(fun, arg, acc) do
    v = %{pending_events: [{0, 0, fun, arg}], seq: 0, acc: acc}
    run(v)
  end

  defp run(%{pending_events: [], acc: acc}), do: acc

  defp run(%{pending_events: [{time, _s, fun, args} | remaining_events],
             acc: acc} = v)
  do
    {new_acc, opts} = fun.(time, args, acc)
    new_events = Keyword.get(opts, :new_events, [])

    v = %{v | pending_events: remaining_events, acc: new_acc}

    v
    |> add_events(time, new_events)
    |> run()
  end

  defp add_events(v, _time, []), do: v
  defp add_events(v, time, new_events) do
    validate_events(new_events)

    Enum.reduce(new_events, v, fn({time_delta, fun, arg}, acc) ->
      schedule(acc, time + time_delta, fun, arg)
    end)
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

  defp schedule(%{pending_events: old_events, seq: seq} = v, time, fun, args)
    when is_integer(time) and time >= 0 and is_function(fun, 3)
  do
    new_event = {time, seq + 1, fun, args}
    new_events = Enum.sort([new_event | old_events])
    %{v | pending_events: new_events, seq: seq + 1}
  end
end
