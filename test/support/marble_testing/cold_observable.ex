defmodule MarbleTesting.ColdObservable do
  @moduledoc false
  defstruct [:events]

  def subscribe(time,
                %__MODULE__{events: events} = observable,
                {r_notifs, subscriptions} = _acc)
  do
    # TODO: Generalize into a subscription function that all observables can impl.
    # TODO: Figure out how to record unsubscription cleanly.

    subscriptions = Map.put(subscriptions, observable, {time, nil})
    {{r_notifs, subscriptions}, new_events: Enum.map(events, &schedule_event/1)}
  end

  defp schedule_event({time, :next, value}), do: {time, &do_next_event/3, value}
  defp schedule_event({time, :done}), do: {time, &do_done_event/3, nil}

  # TODO: Generalize into a subscription wrapper/runner that calls Observable
  # and marshals these responses appropriately.
  defp do_next_event(time, value, {r_notifs, subscriptions} = _acc) do
    {{[{time, :next, value} | r_notifs], subscriptions}, []}
  end
  defp do_done_event(time, nil, {r_notifs, subscriptions} = _acc) do
    # NASTY HACK: There can be only one subscription, right?
    the_one_true_observable = List.first(Map.keys(subscriptions))
    {sub, nil} = subscriptions[the_one_true_observable]
    subscriptions = Map.put(subscriptions, the_one_true_observable, {sub, time})
    {{[{time, :done} | r_notifs], subscriptions}, []}
  end
end
