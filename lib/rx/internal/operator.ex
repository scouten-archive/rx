defmodule Rx.Internal.Operator do
  @moduledoc false
  # Internal module, used to implement operators which consume one or more
  # Observables and produce a new Observable.

  use Rx.Schedulable

  import Rx.Internal.ValidObservable

  @type subscribe_reply ::
    {:ok, state :: any} |
    {:ok, state :: any, options :: keyword}

  @type handle_events_reply ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @callback subscribe(time :: non_neg_integer, stage :: struct) ::
    subscribe_reply

  @callback handle_events(time :: non_neg_integer,
                          events :: [term],
                          state :: term) ::
    handle_events_reply

  @callback handle_done(time :: non_neg_integer,
                        state :: term) ::
    handle_events_reply

  @callback handle_error(time :: non_neg_integer,
                         error :: term,
                         state :: term) ::
    handle_events_reply

  @callback unsubscribe(time :: non_neg_integer,
                        reason :: term,
                        state :: term) :: :ok

  @spec init(time :: number, args :: struct) :: Rx.Schedulable.init_reply
  def init(time, args)

  def init(time, %{__struct__: module,
                   source: source_observable,
                   started_by: observer} = stage)
  do
    enforce(source_observable)
    source_ref = make_ref()
    {:ok, mod_state} = module.subscribe(time, stage)

    state = %{source_ref: source_ref,
              module: module,
              mod_state: mod_state,
              observer: observer}

    {:ok, state, start: [{0, source_ref, source_observable}]}
  end

  def init(_time, %{__struct__: _module} = stage) do
    raise ArgumentError,
          """
          Rx.Internal.Operator can only be used with Observable stages that
          are subscribed to and themselves subscribe to another Observable.

          This struct is missing its "started_by" or "source" member or both.

          #{inspect stage}

          """
  end

  @spec handle_task(time :: number, args :: term, state :: term) ::
    Rx.Schedulable.handle_task_reply
  def handle_task(time, task, state)

  def handle_task(time, {:next, values},
                  %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_events(time, values, mod_state), state)
  def handle_task(time, :done, %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_done(time, mod_state), state)
  def handle_task(time, {:error, error},
                  %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_error(time, error, mod_state), state)

  defp handle_mod_reply({:events, events, mod_state}, state), do:
    dispatch_events(events, mod_state, state, :continue)
  defp handle_mod_reply({:done, events, mod_state}, state), do:
    dispatch_events(events, mod_state, state, :done)
  defp handle_mod_reply({:error, events, error, mod_state}, state), do:
    dispatch_events(events, mod_state, state, {:error, error})

  defp dispatch_events(events, mod_state,
                       %{observer: observer, source_ref: source} = state, status)
  do
    {:ok,
     update_mod_state(state, mod_state),
     send_events(events, observer, status, source)}
  end

  defp update_mod_state(state, mod_state), do:
    %{state | mod_state: mod_state}

  defp send_events([], _observer, :continue, _source), do: []
  defp send_events(events, observer, :continue, _source), do:
    [send: [{0, observer, {:next, events}}]]

  defp send_events([], observer, status, source), do:
    [send: [send_terminate(status, observer)], stop: [{source, :unsubscribe}]]
  defp send_events(events, observer, status, source), do:
    [send: [{0, observer, {:next, events}}, send_terminate(status, observer)],
     stop: [{source, :unsubscribe}]]

  defp send_terminate(:done, observer), do:
    {0, observer, :done}
  defp send_terminate({:error, error}, observer), do:
    {0, observer, {:error, error}}

  @spec terminate(time :: number, reason :: Rx.Schedulable.reason, state :: term) :: :ok
  def terminate(time, reason, %{module: module, mod_state: mod_state}) do
    module.unsubscribe(time, reason, mod_state)
    :ok
  end

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Rx.Internal.Operator

      use Rx.Internal.ValidObservable

      @spec init(time :: number, args :: struct) :: Rx.Schedulable.init_reply
      def init(time, stage), do:
        Rx.Internal.Operator.init(time, stage)

      @spec handle_task(time :: number, args :: term, state :: term) ::
        Rx.Schedulable.handle_task_reply
      def handle_task(time, task, state), do:
        Rx.Internal.Operator.handle_task(time, task, state)

      @spec terminate(time :: number, reason :: Rx.Schedulable.reason, state :: term) :: :ok
      def terminate(time, reason, state), do:
        Rx.Internal.Operator.terminate(time, reason, state)

      @spec subscribe(time :: non_neg_integer, stage :: struct) ::
        Rx.Internal.Operator.subscribe_reply
      def subscribe(_time, _observable), do: {:ok, :no_state}

      @spec unsubscribe(time :: non_neg_integer, reason :: term, state :: term) :: :ok
      def unsubscribe(_time, _reason, _state), do: :ok

      defoverridable [subscribe: 2, unsubscribe: 3]
    end
  end
end
