defmodule OLD.VirtualTimeSchedulerTest do
  use ExUnit.Case, async: true

  alias OLD.VirtualTimeScheduler, as: VTS

  test "can run a preconfigured sequence of events in order of addition" do
    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    init = fn(0, nil, acc) ->
      {acc, new_events: [{0, invoke, 1},
                         {0, invoke, 2},
                         {0, invoke, 3},
                         {0, invoke, 4},
                         {0, invoke, 5}]}
    end

    assert init |> VTS.run(nil, []) |> Enum.reverse() ==
      [{0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}]
  end

  test "can run tasks in order sorted by time, even if scheduled at random" do
    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    init = fn(0, nil, acc) ->
      {acc, new_events: [{0, invoke, 1},
                         {100, invoke, 2},
                         {0, invoke, 3},
                         {500, invoke, 4},
                         {0, invoke, 5},
                         {100, invoke, 6}]}
    end

    assert init |> VTS.run(nil, []) |> Enum.reverse() ==
      [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  test "can run tasks that call different functions" do
    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    reverse = fn(_time, :ignore, acc) ->
      {Enum.reverse(acc), []}
    end

    init = fn(0, nil, acc) ->
      {acc, new_events: [{0, invoke, 1},
                         {100, invoke, 2},
                         {0, invoke, 3},
                         {500, invoke, 4},
                         {0, invoke, 5},
                         {100, invoke, 6},
                         {700, reverse, :ignore}]}
    end

    assert VTS.run(init, nil, []) ==
      [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  test "does not accept negative delays" do
    # NOTE: This differs from RxJS implementation. Maybe we'll have to revisit?

    init = fn(_, _, _) ->
      {:whatever, new_events: [{-10, fn _time, _arg, _acc -> :noop end, 1}]}
    end

    assert_raise ArgumentError, fn ->
      VTS.run(init, nil, [])
    end
  end

  defp recursive_invoke(time, n, acc) do
    new_events = if n < 4, do: [{0, &recursive_invoke/3, n + 1}], else: []
    {[{time, n} | acc], new_events: new_events}
  end

  test "can schedule new events at same 'time' while running" do
    assert Enum.reverse(VTS.run(&recursive_invoke/3, 1, [])) ==
      [{0, 1}, {0, 2}, {0, 3}, {0, 4}]
  end

  defp recursive_invoke_with_delay(time, n, acc) do
    new_events = if n < 4, do: [{10, &recursive_invoke_with_delay/3, n + 1}], else: []
    {[{time, n} | acc], new_events: new_events}
  end

  test "can schedule new events at later 'time' while running" do
    assert Enum.reverse(VTS.run(&recursive_invoke_with_delay/3, 1, [])) ==
      [{0, 1}, {10, 2}, {20, 3}, {30, 4}]
  end
end
