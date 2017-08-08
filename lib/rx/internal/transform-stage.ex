defmodule Rx.Internal.TransformStage do
  @moduledoc ~S"""
  This module should be used to implement Rx stages that transform existing Observables.

  It derives from GenStage and provides some additional callback functions.

  TODO: Write more documentation here. Adapt from GenStage docs as appropriate.
  """

  use GenStage

  defstruct [:mod, :state, :producer, :consumer]

  @typedoc "The supported init options."
  @type options :: keyword()

  # TODO: Docs
  @spec start(module, term, GenStage.options) :: GenServer.on_start
  def start(module, args, options \\ []) when is_atom(module) and is_list(options) do
    GenStage.start(__MODULE__, {module, args}, options)
  end

  @doc ~S"""
  Invoked when the server is started.

  `start_link/3` (or `start/3`) will block until this callback returns.
  `args` is the argument term (second argument) passed to `start_link/3`
  (or `start/3`).

  TODO: Describe what must be returned. Doesn't exactly match GenStage.
  Give examples.
  """
  @callback init(args :: term) ::
    {:ok, options, state} |
    {:stop, reason :: any} when state: any

  @doc ~S"""
  Invoked when the upstream producer generates events.
  """
  @callback handle_events(events :: [term], state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @doc ~S"""
  Invoked when the upstream producer terminates normally.
  """
  @callback handle_done(state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @doc ~S"""
  Invoked when the upstream producer terminates with an error.
  """
  @callback handle_error(events :: [term], state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

    @doc false
    def init({mod, args}) do
      case mod.init(args) do
        {:ok, opts, state} ->
          init_transform(mod, opts, state)
        {:stop, _} = stop ->
          stop
        other ->
          {:stop, {:bad_return_value, other}}
      end
    end

    defp init_transform(mod, opts, state) do
      {:producer_consumer,
       %Rx.Internal.TransformStage{mod: mod,
                                   state: state,
                                   producer: nil,
                                   consumer: nil},
       opts}
    end

  @doc false
  def handle_subscribe(:producer, _opts, sub, %__MODULE__{producer: nil} = state), do:
    {:automatic, %{state | producer: sub}}
  def handle_subscribe(:consumer, _opts, sub, %__MODULE__{consumer: nil} = state), do:
    {:automatic, %{state | consumer: sub}}
  def handle_subscribe(type, _opts, sub, state) do
    :error_logger.info_msg("""
    Rx.Internal.TransformStage is stopping after invalid subscription request
      type = #{inspect type}
      subscription = #{inspect sub}
      state = #{inspect state}

    """)

    {:stop, :invalid_subscription}
  end

  @doc false
  def handle_events(events, _from, %__MODULE__{mod: mod} =  state) do
    handle_event_reply(mod.handle_events(events, state.state), :handle_events, state)
  end

  def handle_cancel({:down, :normal}, from,
                    %__MODULE__{mod: mod, producer: from} = state)
  do
    handle_event_reply(mod.handle_done(state.state), :handle_done, state)
  end

  def handle_cancel({:down, {:shutdown, %Rx.Error{message: message}}}, from,
                    %__MODULE__{mod: mod, producer: from} = state)
  do
    handle_event_reply(mod.handle_error(message, state.state), :handle_error, state)
  end

  def handle_cancel({:down, {:shutdown, error}}, from,
                    %__MODULE__{mod: mod, producer: from} = state)
  do
    handle_event_reply(mod.handle_error(error, state.state), :handle_error, state)
  end

  defp handle_event_reply({:events, events, mod_state}, _fn_name, state)
    when is_list(events)
  do
    {:noreply, events, %{state | state: mod_state}}
  end

  defp handle_event_reply({:done, events, mod_state}, _fn_name, state)
    when is_list(events)
  do
    {pid, refs} = state.consumer
    Process.send(pid, {:"$gen_consumer", {self(), refs}, events}, [:noconnect])
    {:stop, :normal, %{state | state: mod_state}}
  end

  defp handle_event_reply({:error, events, reason, mod_state}, _fn_name, state)
    when is_list(events)
  do
    {pid, refs} = state.consumer
    Process.send(pid, {:"$gen_consumer", {self(), refs}, events}, [:noconnect])
    {:stop, translate_reason(reason), %{state | state: mod_state}}
  end

  defp handle_event_reply(other, fn_name, state) do
    :error_logger.info_msg("""
    Rx.Internal.TransformStage is stopping after invalid reply
    from #{inspect state.mod}.#{inspect fn_name}

      reply = #{inspect other}
      state = #{inspect state}

    """)

    {:stop, :invalid_reply, state}
  end

  defp translate_reason(:normal), do: :done
  defp translate_reason(%Rx.Error{message: message}), do: {:error, message}
  defp translate_reason(reason), do: {:error, reason}

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Rx.Internal.TransformStage

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      @doc false
      def code_change(_old, state, _extra) do
        {:ok, state}
      end

      defoverridable [terminate: 2, code_change: 3]
    end
  end
end
