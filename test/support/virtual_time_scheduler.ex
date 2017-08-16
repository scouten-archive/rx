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

  def run(%__MODULE__{pending_events: [{time, _s, fun, args} | events],
                      seq: _seq, acc: acc} = v)
  do
    {new_acc, _new_events} = fun.(time, args, acc)
    run(%{v | pending_events: events, acc: new_acc})
  end
end
