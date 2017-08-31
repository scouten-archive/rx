defmodule Rx.Observer do
  @moduledoc ~S"""
  A behaviour module for implementing the observer portion of an Observable-Observer
  relationship.

  Though it bears some similarity to `GenServer`, an `Observer` typically does not
  run in its own process.

  The callbacks will be called in the following sequence for each subscription:

  * `c:subscribe/2` exactly once
  * `c:handle_events/3` zero or more times
  * `c:handle_done/2` or `c:handle:error/3` (only one of these, only once)
  * `c:unsubscribe/3` exactly once

  The `state` value is initially returned by `c:subscribe/2` and then passed
  to each of the following callbacks. It can be used to pass any state that should
  be retained across invocations. The value is not interpreted by RxElixir code
  in any way.

  Each of the callbacks except `c:unsubscribe/3` must return one of the following values:

  * `{:ok, state}` - continue observation and update `state` for next callback
  * `{:stop, state}` - abort observation; `state` will be passed to `c:unsubscribe/3`
  """

  use Rx.Schedulable

  import Rx.Internal.ValidObservable

  @doc ~S"""
  Called at the beginning of each subscription.

  `args` will be the struct that was passed to any "subscribe" function.
  """
  @callback subscribe(time :: non_neg_integer, args :: term) ::
    {:ok, state} |
    {:stop, reason :: any} when state: any

  @doc ~S"""
  Respond to one or more event values generated by the upstream Observable.
  """
  @callback handle_events(time :: non_neg_integer, values :: [term], state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @doc ~S"""
  Respond to successful completion of the upstream Observable.
  """
  @callback handle_done(time :: non_neg_integer, state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @doc ~S"""
  Respond to error termination of the upstream Observable.
  """
  @callback handle_error(time :: non_neg_integer, error :: term, state :: term) ::
    {:ok, state :: term} |
    {:stop, reason :: any}

  @doc ~S"""
  Called at the end of the subscription, regardless of cause.

  Release any resources associated with this Observer.
  """
  @callback unsubscribe(time :: non_neg_integer, reason, state :: term) ::
    term when reason: :done | :cancel | {:error, term}

  @doc false
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

  @doc false
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
  defp handle_mod_reply({:stop, mod_state}, state, _fun), do:
    maybe_terminate(state, mod_state, [], :stop)
  defp handle_mod_reply({:stop, mod_state, opts}, state, _fun), do:
    maybe_terminate(state, mod_state, opts, :stop)
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

  @doc false
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
      def handle_events(_time, _values, state), do: {:ok, state}
      def handle_done(_time, state), do: {:stop, state}
      def handle_error(_time, _error, state), do: {:stop, state}
      def unsubscribe(_time, _reason, _state), do: :ok

      defoverridable [init: 2, # should only be done by Rx.Internal.*
                      subscribe: 2,
                      handle_events: 3,
                      handle_done: 2,
                      handle_error: 3,
                      unsubscribe: 3]
    end
  end
end
