defmodule Rx.Observer do
  @moduledoc ~S"""
  A behaviour module for implementing the observer portion of an Observable-Observer
  relationship.

  Though it bears some similarity to GenServer, an Observer does not necessarily
  run in its own process. Its lifetime is bounded by `subscribe` and `unsubscribe`
  events that are passed to it by its execution context. Between those two events,
  a `state` parameter can be used to pass any state that should be retained across
  invocations.

  TODO: Write more docs.
  """

  use Rx.Schedulable

  import Rx.Internal.ValidObservable

  @callback subscribe(time :: non_neg_integer, args :: term) ::
    {:ok, state} |
    {:stop, reason :: any} when state: any

  @callback handle_values(time :: non_neg_integer, values :: [term], state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @callback handle_done(time :: non_neg_integer, state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @callback handle_error(time :: non_neg_integer, error :: term, state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @callback unsubscribe(time :: non_neg_integer, reason, state :: term) ::
    term when reason: :done | :cancel | {:error, term}

  # TODO: Add a variant without source_observable because it won't work
  # for hot Observables.
  def init(time, %{__struct__: module,
                   source: source_observable} = observer)
  do
    enforce(source_observable)
    source_ref = make_ref()

    state = %{source_ref: source_ref,
              module: module,
              mod_state: nil,
              terminated: false}

    sub_reply = handle_mod_reply(module.subscribe(time, observer),
                                 state, :subscribe)

    start_source_observable(sub_reply, source_observable)
  end

  defp start_source_observable({:ok, %{source_ref: source_ref} = state, opts},
                               source_observable), do:
    {:ok, state, add_start(opts, source_ref, source_observable)}
  defp start_source_observable({:ok, %{source_ref: source_ref} = state},
                               source_observable), do:
    {:ok, state, add_start([], source_ref, source_observable)}
  defp start_source_observable(other_reply, _source_observable), do: other_reply

  defp add_start(opts, source_ref, source_observable) do
    start = Keyword.get(opts, :start, [])
    Keyword.put(opts, :start, [{0, source_ref, source_observable} | start])
  end

  def handle_task(_time, _task, %{terminated: true} = state), do:
    {:ok, state}
  def handle_task(time, {:next, values},
                  %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_events(time, values, mod_state),
                     state, :handle_events)
  def handle_task(time, :done, %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_done(time, mod_state),
                     state, :handle_done)
  def handle_task(time, {:error, error},
                  %{module: module, mod_state: mod_state} = state), do:
    handle_mod_reply(module.handle_error(time, error, mod_state),
                     state, :handle_error)

  defp handle_mod_reply({:ok, mod_state}, state, fun), do:
    maybe_terminate(state, mod_state, [], status_for_fun(fun))
  defp handle_mod_reply({:ok, mod_state, opts}, state, fun), do:
    maybe_terminate(state, mod_state, opts, status_for_fun(fun))
  defp handle_mod_reply(bad_reply, state, fun), do:
    raise ArgumentError,
      """
      Invalid Rx.Observer callback reply received.

      Rx.Observer callback #{inspect state.module}.#{fun}

      replied with #{inspect bad_reply}

      """

  defp status_for_fun(:handle_done), do: :stop
  defp status_for_fun(:handle_error), do: :stop
  defp status_for_fun(_), do: :continue

  defp maybe_terminate(state, mod_state, opts, :continue), do:
    {:ok, update_mod_state(state, mod_state), opts}
  defp maybe_terminate(state, mod_state, opts, _status), do:
    {:stop, state |> update_mod_state(mod_state) |> mark_terminated(),
     add_stop_source(opts, state)}

  defp update_mod_state(state, mod_state), do:
    %{state | mod_state: mod_state}

  defp add_stop_source(opts, %{source_ref: source_ref}) do
    stop = Keyword.get(opts, :stop, [])
    Keyword.put(opts, :stop, [{source_ref, :unsubscribe} | stop])
  end

  defp mark_terminated(state), do:
    %{state | terminated: true}

  def terminate(time, reason, %{module: module, mod_state: mod_state}), do:
    module.unsubscribe(time, reason, mod_state)

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Rx.Observer

      def init(time, stage), do:
        Rx.Observer.init(time, stage)

      def handle_task(time, task, state), do:
        Rx.Observer.handle_task(time, task, state)

      def terminate(time, reason, state), do:
        Rx.Observer.terminate(time, reason, state)

      def subscribe(_time, _args), do: {:ok, :no_state}
      def handle_values(_time, _values, state), do: {:ok, state}
      def handle_done(_time, state), do: {:stop, state}
      def handle_error(_time, _error, state), do: {:stop, state}
      def unsubscribe(_time, _reason, _state), do: :ok

      defoverridable [init: 2, # should only be done by Rx.Internal.*
                      subscribe: 2,
                      handle_values: 3,
                      handle_done: 2,
                      handle_error: 3,
                      unsubscribe: 3]
    end
  end
end
