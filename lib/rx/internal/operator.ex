defmodule Rx.Internal.Operator do
  @moduledoc false
  # Internal module, used to implement operators which consume one or more
  # Observables and produce a new Observable.

  use Rx.Observer

  import Rx.Internal.ValidObservable

  @callback subscribe(time :: non_neg_integer, stage :: struct) ::
    {:ok, state} |
    {:ok, state, options :: keyword} when state: any

  @callback handle_events(time :: non_neg_integer,
                          events :: [term],
                          state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @callback handle_done(time :: non_neg_integer,
                        state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @callback handle_error(time :: non_neg_integer,
                         error :: term,
                         state :: term) ::
    {:events, events :: [term], state :: term} |
    {:done, events :: [term], state :: term} |
    {:error, events :: [term], state :: term}

  @callback unsubscribe(time :: non_neg_integer,
                        reason :: term,
                        state :: term) :: :ok

  defstruct [:source, :started_by, :operator]

  def init(time, %{__struct__: _module,
                   source: source_observable,
                   started_by: observer} = operator)
  do
    Rx.Observer.init(time, %__MODULE__{source: enforce(source_observable),
                                       started_by: observer,
                                       operator: operator})
  end

  def init(_time, %{__struct__: _module} = operator) do
    raise ArgumentError,
          """
          Rx.Internal.Operator can only be used with Observable stages that
          are subscribed to and themselves subscribe to another Observable.

          This struct is missing its "started_by" or "source" member or both:

          #{inspect operator}

          """
  end

  def subscribe(time, %__MODULE__{operator: %{__struct__: module} = operator,
                                  started_by: observer}), do:
    handle_mod_reply(module.subscribe(time, operator),
                     %{module: module, mod_state: nil, observer: observer})

  def handle_events(time, values, %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_events(time, values, mod_state), state)

  def handle_done(time, %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_done(time, mod_state), state)

  def handle_error(time, error, %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_error(time, error, mod_state), state)

  defp handle_mod_reply({:ok, mod_state}, state), do:
    dispatch_events([], mod_state, state, :continue)
  defp handle_mod_reply({:events, events, mod_state}, state), do:
    dispatch_events(events, mod_state, state, :continue)
  defp handle_mod_reply({:done, events, mod_state}, state), do:
    dispatch_events(events, mod_state, state, :done)
  defp handle_mod_reply({:error, events, error, mod_state}, state), do:
    dispatch_events(events, mod_state, state, {:error, error})

  defp dispatch_events(events, mod_state,
                       %{observer: observer} = state,
                       status)
  do
    {ok_or_stop(status),
     update_mod_state(state, mod_state),
     send_events(events, observer, status)}
  end

  defp ok_or_stop(:continue), do: :ok
  defp ok_or_stop(:events), do: :ok
  defp ok_or_stop(_), do: :stop

  defp update_mod_state(state, mod_state), do:
    %{state | mod_state: mod_state}

  defp send_events([], _observer, :continue), do: []
  defp send_events(events, observer, :continue), do:
    [send: [{0, observer, {:next, events}}]]

  defp send_events([], observer, status), do:
    [send: [send_terminate(status, observer)]]
  defp send_events(events, observer, status), do:
    [send: [{0, observer, {:next, events}}, send_terminate(status, observer)]]

  defp send_terminate(:done, observer), do:
    {0, observer, :done}
  defp send_terminate({:error, error}, observer), do:
    {0, observer, {:error, error}}

  def unsubscribe(time, reason, %{module: module, mod_state: mod_state}), do:
    module.unsubscribe(time, reason, mod_state)

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Rx.Internal.Operator

      use Rx.Internal.ValidObservable

      def init(time, stage), do:
        Rx.Internal.Operator.init(time, stage)

      def handle_task(time, task, state), do:
        Rx.Observer.handle_task(time, task, state)

      def terminate(time, reason, state), do:
        Rx.Observer.terminate(time, reason, state)

      def subscribe(_time, _observable), do: {:ok, :no_state}
      def handle_events(_time, _values, state), do: {:ok, state}
      def handle_done(_time, state), do: {:stop, state}
      def handle_error(_time, _error, state), do: {:stop, state}
      def unsubscribe(_time, _reason, _state), do: :ok

      defoverridable [subscribe: 2,
                      handle_events: 3,
                      handle_done: 2,
                      handle_error: 3,
                      unsubscribe: 3]
    end
  end
end
