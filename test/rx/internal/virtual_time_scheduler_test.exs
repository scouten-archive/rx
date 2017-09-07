defmodule VirtualTimeSchedulerTest do
  use ExUnit.Case, async: true

  alias VirtualTimeScheduler, as: VTS

  # ---

  defmodule SimpleSchedulable do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(%__MODULE__{} = _) do
      {:ok, [], new_tasks: [{0, {:append, 1}},
                            {0, {:append, 2}},
                            {0, {:append, 3}},
                            {0, {:append, 4}},
                            {0, {:append, 5}}]}
    end

    def handle_task({:append, n}, acc), do:
      {:ok, [{VTS.time_now(), n} | acc]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "can run a preconfigured sequence of events in order of addition" do
    assert VTS.run(%SimpleSchedulable{}) ==
      [{0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}]
  end

  # ---

  defmodule RandomScheduler do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(%__MODULE__{} = _) do
      {:ok, [], new_tasks: [{0, {:append, 1}},
                            {100, {:append, 2}},
                            {0, {:append, 3}},
                            {500, {:append, 4}},
                            {0, {:append, 5}},
                            {100, {:append, 6}}]}
    end

    def handle_task({:append, n}, acc), do:
      {:ok, [{VTS.time_now(), n} | acc]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "can run tasks in order sorted by time, even if scheduled at random" do
    assert VTS.run(%RandomScheduler{}) ==
      [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  # ---

  defmodule ReversingScheduler do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(%__MODULE__{} = _) do
      {:ok, [], new_tasks: [{0, {:append, 1}},
                            {100, {:append, 2}},
                            {0, {:append, 3}},
                            {500, {:append, 4}},
                            {0, {:append, 5}},
                            {100, {:append, 6}},
                            {700, :reverse}]}
    end

    def handle_task({:append, n}, acc), do: {:ok, [{VTS.time_now(), n} | acc]}
    def handle_task(:reverse, acc), do: {:ok, Enum.reverse(acc)}

    def terminate(_reason, acc), do: acc
  end

  test "can run tasks that call different functions" do
    assert VTS.run(%ReversingScheduler{}) ==
      [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  # ---

  defmodule BackwardsScheduler do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(_), do: {:ok, [], new_tasks: [{-10, :whatever}]}
    def handle_task(_, acc), do: {:ok, acc}
    def terminate(_reason, acc), do: acc
  end

  test "does not accept negative delays" do
    # NOTE: This differs from RxJS implementation. Maybe we'll have to revisit?

    assert_raise ArgumentError, fn ->
      VTS.run(%BackwardsScheduler{})
    end
  end

  # ---

  defmodule RecursiveScheduler do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(_), do: {:ok, [], new_tasks: [{0, {:append, 1}}]}

    def handle_task({:append, n}, acc) when n > 4, do: {:ok, acc}
    def handle_task({:append, n}, acc), do:
      {:ok, [{0, n} | acc], new_tasks: [{0, {:append, n + 1}}]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "can schedule new events at same 'time' while running" do
    assert VTS.run(%RecursiveScheduler{}) ==
      [{0, 1}, {0, 2}, {0, 3}, {0, 4}]
  end

  # ---

  defmodule RecursiveSchedulerWithDelay do
    use Rx.Schedulable

    defstruct placeholder: nil

    def init(_), do: {:ok, [], new_tasks: [{10, {:append, 1}}]}

    def handle_task({:append, n}, acc) when n > 4, do: {:ok, acc}
    def handle_task({:append, n}, acc), do:
      {:ok, [{VTS.time_now(), n} | acc], new_tasks: [{10, {:append, n + 1}}]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "can schedule new events at later 'time' while running" do
    assert VTS.run(%RecursiveSchedulerWithDelay{}) ==
      [{10, 1}, {20, 2}, {30, 3}, {40, 4}]
  end

  # ---

  defmodule StatefulSchedulable do
    use Rx.Schedulable

    defstruct starting_count: 0

    def init(%__MODULE__{starting_count: starting_count}),
      do: {:ok, [], new_tasks: [{10, {:append, starting_count}}]}

    def handle_task({:append, n}, acc) when n > 45, do: {:ok, acc}
    def handle_task({:append, n}, acc), do:
      {:ok, [{VTS.time_now(), n} | acc], new_tasks: [{10, {:append, n + 1}}]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "passes arguments through from original struct to init func" do
    assert VTS.run(%StatefulSchedulable{starting_count: 42}) ==
      [{10, 42}, {20, 43}, {30, 44}, {40, 45}]
  end

  # ---

  defmodule PongSchedulable do
    use Rx.Schedulable

    defstruct starting_count: 0, started_by: nil

    def init(%__MODULE__{starting_count: starting_count, started_by: ping_ref}),
      do: {:ok, ping_ref, new_tasks: [{0, {:send, starting_count}}]}

    def handle_task({:send, n}, ping_ref), do:
      {:ok, ping_ref, new_tasks: [{20, {:send, n - 1}}],
                      send: [{0, ping_ref, {:ping, n}}]}

    def terminate(_reason, _ping_ref) do
      send(self(), {:pong_terminated, VTS.time_now()})
      :ok
    end
  end

  defmodule PingSchedulable do
    use Rx.Schedulable

    defstruct starting_count: 0

    def init(%__MODULE__{starting_count: starting_count}),
      do: {:ok, [], new_tasks: [{10, {:append, starting_count}},
                                {15, :start_pong},
                                {65, :stop_pong}]}

    def handle_task({:append, n}, acc) when n > 45, do: {:ok, acc}
    def handle_task({:append, n}, acc), do:
      {:ok, [{VTS.time_now(), n} | acc], new_tasks: [{20, {:append, n + 1}}]}

    def handle_task(:start_pong, acc), do:
      {:ok, acc, start: [{5, :pong, %PongSchedulable{starting_count: -1}}]}

    def handle_task(:stop_pong, acc), do:
      {:ok, acc, stop: [{:pong, :mumble}]}

    def handle_task({:ping, value}, acc), do:
      {:ok, [{VTS.time_now(), value} | acc]}

    def terminate(_reason, acc), do: Enum.reverse(acc)
  end

  test "can have multiple schedulable structs at once" do
    assert VTS.run(%PingSchedulable{starting_count: 42}) ==
      [{10, 42}, {20, -1},
       {30, 43}, {40, -2},
       {50, 44}, {60, -3},
       {70, 45}]

    assert_received {:pong_terminated, 65}
  end
end
