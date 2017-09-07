defmodule VirtualTimeScheduler do
  @moduledoc false  # Only used in testing infrastructure.

  defstruct pending_tasks: [],
            task_seq: 0,
            modules: %{},
            sub_states: %{},
            terminate_results: %{},
            root: 0

  def run(%{__struct__: _module} = first_schedulable) do
    root = make_ref()

    %__MODULE__{root: root}
    |> schedule_init(0, root, first_schedulable)
    |> run_tasks()
  end

  defp run_tasks(%__MODULE__{pending_tasks: []} = v), do: v.terminate_results[v.root]
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
    put_time(time)
    {:init, time, sid, module.init(schedulable)}
  end

  defp run_task(%__MODULE__{modules: modules, sub_states: sub_states},
                {time, _seq, sid, {:task, task}})
  do
    put_time(time)
    module = Map.get(modules, sid)
    sub_state = Map.get(sub_states, sid)
    {:task, time, sid, module.handle_task(task, sub_state)}
  end

  defp run_task(%__MODULE__{modules: modules, sub_states: sub_states},
                {time, _seq, sid, {:terminate, reason}})
  do
    put_time(time)
    module = Map.get(modules, sid)
    sub_state = Map.get(sub_states, sid)

    case module do
      nil -> :nop
      _ -> {:terminate, time, sid, module.terminate(reason, sub_state)}
    end
  end

  defp put_time(time), do:
    Process.put(:virtual_time_scheduler_time, time)

  defp handle_options(:nop, v), do: v

  defp handle_options({:terminate, _time, sid, terminate_results}, v) do
    %{v | pending_tasks: Enum.reject(v.pending_tasks,
                                     fn {_msg, _time, tsid, _args} -> sid == tsid end),
          sub_states: Map.delete(v.sub_states, sid),
          modules: Map.delete(v.modules, sid),
          terminate_results: Map.put(v.terminate_results, sid, terminate_results)}
  end

  defp handle_options({callback, time, sid, {:ok, sub_state}}, v) do
    handle_options({callback, time, sid, {:ok, sub_state, []}}, v)
  end

  defp handle_options({_callback, time, sid, {:ok, sub_state, options}}, v) do
    v
    |> put_sub_state(sid, sub_state)
    |> start_new_schedulables(time, sid, Keyword.get(options, :start, []))
    |> stop_schedulables(time, Keyword.get(options, :stop, []))
    |> add_tasks(time, sid, Keyword.get(options, :new_tasks, []))
    |> send_messages(time, Keyword.get(options, :send, []))
  end

  defp handle_options({callback, time, sid, {:stop, sub_state}}, v) do
    handle_options({callback, time, sid, {:stop, sub_state, []}}, v)
  end

  defp handle_options({_callback, time, sid, {:stop, sub_state, options}}, v) do
    v
    |> put_sub_state(sid, sub_state)
    |> start_new_schedulables(time, sid, Keyword.get(options, :start, []))
    |> stop_schedulables(time, [{sid, :normal} | Keyword.get(options, :stop, [])])
    |> add_tasks(time, sid, Keyword.get(options, :new_tasks, []))
    |> send_messages(time, Keyword.get(options, :send, []))
  end

  defp put_sub_state(%__MODULE__{sub_states: sub_states} = v,
                     sid, sub_state)
  do
    %{v | sub_states: Map.put(sub_states, sid, sub_state)}
  end

  defp start_new_schedulables(v, _time, _sid, []), do: v

  defp start_new_schedulables(v, time, sid, new_schedulables) do
    validate_schedulables(new_schedulables)

    Enum.reduce(new_schedulables, v, fn({time_delta, new_sid, schedulable}, acc) ->
      schedule_init(acc, time + time_delta, new_sid,
                    maybe_add_started_by(schedulable, sid))
    end)
  end

  defp validate_schedulables(schedulables) do
    unless Enum.all?(schedulables, &validate_schedulable/1), do:
      raise ArgumentError,
        "invalid schedulables passed to VTS run callback\n#{inspect schedulables}"
  end

  defp validate_schedulable({time, _sid, %{__struct__: _module}})
    when is_integer(time) and time >= 0, do: true
  defp validate_schedulable(_), do: false

  defp maybe_add_started_by(%{started_by: _placeholder} = s, sid), do:
    %{s | started_by: sid}
  defp maybe_add_started_by(s, _sid), do: s

  defp stop_schedulables(v, _time, []), do: v

  defp stop_schedulables(v, time, schedulables_to_stop) do
    validate_stops(schedulables_to_stop)

    Enum.reduce(schedulables_to_stop, v, fn({sid, reason}, acc) ->
      schedule_terminate(acc, time, sid, reason)
    end)
  end

  defp validate_stops(schedulables) do
    unless Enum.all?(schedulables, &validate_stop/1), do:
      raise ArgumentError,
        "invalid stop request passed to VTS run callback\n#{inspect schedulables}"
  end

  defp validate_stop({_sid, _reason}), do: true
  defp validate_stop(_), do: false

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
  end

  defp validate_task({time, _task}) when is_integer(time) and time >= 0, do: true
  defp validate_task(_), do: false

  defp send_messages(v, _time, []), do: v

  defp send_messages(v, time, messages) do
    validate_messages(messages)

    Enum.reduce(messages, v, fn({time_delta, target_sid, message}, acc) ->
      add_task(acc, time + time_delta, target_sid, {:task, message})
    end)
  end

  defp validate_messages(messages) do
    unless Enum.all?(messages, &validate_message/1), do:
      raise ArgumentError,
            "invalid message passed to VTS run callback\n#{inspect messages}"
  end

  defp validate_message({time, _target_sid, _message})
    when is_integer(time) and time >= 0, do: true
  defp validate_message(_), do: false

  defp schedule_init(%__MODULE__{modules: modules} = v,
                     time_now, sid,
                     %{__struct__: module} = schedulable)
  do
    v = add_task(%{v | modules: Map.put(modules, sid, module)},
                 time_now, sid, {:init, schedulable})

    schedule_terminate(v, :done, sid, :normal)
  end

  defp schedule_terminate(%__MODULE__{} = v, time, sid, reason), do:
    add_task(v, time, sid, {:terminate, reason})

  defp add_task(%__MODULE__{pending_tasks: old_tasks, task_seq: seq} = v,
                time, sid, task)
  do
    new_task = {time, seq + 1, sid, task}
    %{v | pending_tasks: Enum.sort([new_task | old_tasks]), task_seq: seq + 1}
  end

  def time_now do
    case Process.get(:virtual_time_scheduler_time) do
      time when is_integer(time) ->
        time
      :done ->
        :done
      nil ->
        raise RuntimeError, "VirtualTimeScheduler.time_now/0 invalid outside of a test"
    end
  end
end
