defmodule Rx.Schedulable do
  @moduledoc false  # TODO: Write documentation for this module.
  # Think of these as micro-tasks within an existing process.

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Rx.Schedulable

      @spec terminate(time :: number, reason :: reason, state :: term) :: :ok
      def terminate(_time, _reason, _state), do: :ok

      defoverridable [terminate: 3]
    end
  end

  @type reason :: :normal | :shutdown | {:shutdown, term} | term

  @type init_reply ::
    {:ok, state} |
    {:ok, state :: term, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: reason}

  @type handle_task_reply ::
    {:ok, new_state :: term} |
    {:ok, new_state :: term, opts} |
    {:stop, reason :: reason, new_state} |
    {:stop, reason :: reason, new_state, opts: [term]}

  @callback init(time :: number, args :: term) ::
    init_reply

  @callback handle_task(time :: number, args :: term, state :: term) ::
    handle_task_reply

  @callback terminate(time :: number, reason :: reason, state :: term) ::
    any
end
