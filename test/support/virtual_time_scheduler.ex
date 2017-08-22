defmodule VirtualTimeScheduler do
  @moduledoc false  # Only used in testing infrastructure.

  defstruct pending_tasks: [],
            task_seq: 0,
            modules: %{},
            sub_states: %{},
            schedulable_seq: 0,
            terminate_results: %{}

  def run(%{__struct__: _module} = first_schedulable) do
    %__MODULE__{}
    |> schedule_init(0, first_schedulable)
    |> schedule_terminate(:done, 1, :normal)
    |> run_tasks()
  end

  defp run_tasks(%__MODULE__{pending_tasks: []} = v), do: v.terminate_results[1]
  defp run_tasks(%__MODULE__{pending_tasks: [current_task | remaining_tasks]} = v) do
    v = %{v | pending_tasks: remaining_tasks}

    v
    |> run_task(current_task)
    |> handle_options(v)
    |> run_tasks()
  end

  defp run_task(%__MODULE__{},
                {time, _seq, sid, {:init, %{__struct__: module} = schedulable}})
  do
    {:init, time, sid, module.init(time, schedulable)}
  end

  defp run_task(%__MODULE__{modules: modules, sub_states: sub_states},
                {time, _seq, sid, {:task, task}})
  do
    module = Map.get(modules, sid)
    sub_state = Map.get(sub_states, sid)
    IO.puts """

    run_task
      task = #{inspect task}
      sid = #{inspect sid}
      module = #{inspect module}
      sub_state = #{inspect sub_state}

    """
    {:task, time, sid, module.handle_task(time, task, sub_state )}
  end

  defp run_task(%__MODULE__{modules: modules, sub_states: sub_states},
                {time, _seq, sid, {:terminate, reason}})
  do
    module = Map.get(modules, sid)
    sub_state = Map.get(sub_states, sid)

    case module do
      nil -> :nop
      _ -> {:terminate, time, sid, module.terminate(time, reason, sub_state)}
    end
  end

  defp handle_options(:nop, v), do: v

  defp handle_options({:terminate, _time, sid, terminate_results}, v) do
    %{v | sub_states: Map.delete(v.sub_states, sid),
          modules: Map.delete(v.modules, sid),
          terminate_results: Map.put(v.terminate_results, sid, terminate_results)}
  end

  defp handle_options({callback, time, sid, {:ok, sub_state}}, v) do
    handle_options({callback, time, sid, {:ok, sub_state, []}}, v)
  end

  defp handle_options({_callback, time, sid, {:ok, sub_state, options}}, v) do
    v
    |> put_sub_state(sid, sub_state)
    |> add_tasks(time, sid, Keyword.get(options, :new_tasks, []))
  end

  defp put_sub_state(%__MODULE__{sub_states: sub_states} = v,
                     sid, sub_state)
  do
    %{v | sub_states: Map.put(sub_states, sid, sub_state)}
  end

  defp add_tasks(v, _time, _sid, []), do: v

  defp add_tasks(v, time, sid, new_tasks) do
    validate_tasks(new_tasks)

    Enum.reduce(new_tasks, v, fn({time_delta, task}, acc) ->
      add_task(acc, time + time_delta, sid, {:task, task})
    end)
  end

  defp validate_tasks(tasks) do
    unless Enum.all?(tasks, &validate_task/1), do:
      raise ArgumentError, "invalid task passed to VTS run callback\n#{inspect tasks}"

    tasks
  end

  defp validate_task({time, _task}) when is_integer(time) and time >= 0, do: true
  defp validate_task(_), do: false

  defp schedule_init(%__MODULE__{schedulable_seq: sseq, modules: modules} = v,
                     time_now,
                     %{__struct__: module} = schedulable)
  do
    add_task(%{v | schedulable_seq: sseq + 1,
                   modules: Map.put(modules, sseq + 1, module)},
             time_now, sseq + 1, {:init, schedulable})
  end

  defp schedule_terminate(%__MODULE__{} = v, time, sid, reason) do
    add_task(v, time, sid, {:terminate, reason})
  end

  defp add_task(%__MODULE__{pending_tasks: old_tasks, task_seq: seq} = v,
                time, sid, task)
  do
    new_task = {time, seq + 1, sid, task}
    %{v | pending_tasks: Enum.sort([new_task | old_tasks]), task_seq: seq + 1}
  end
end
