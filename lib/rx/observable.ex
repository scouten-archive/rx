defmodule Rx.Observable do
  @moduledoc ~S"""
  An Observable is a recipe for expressing, transforming, and processing one or
  more asynchronous data streams.

  Like [`Stream`](https://hexdocs.pm/elixir/Stream.html), an Observable is lazy.
  The recipe is created, but it does nothing until an `Observer` listens to it.

  Unlike `Stream`, an Observable need not block the process in which it is created.
  For example, an Observable may be wired up to generate messages to the creating
  process, which can be handled in the `handle_info` callback of a `GenServer` or
  similar.

  Unlike `Stream`, an Observable may be implemented by orchestrating one or more
  Elixir/OTP processes, depending on the structure of the recipe. A user of
  RxElixir need not dive deeply into this implmentation detail, except, perhaps
  to think of RxElixir as a factory for `GenServer` processes which work together
  to implement the desired computation.

  TODO: Rewrite to reflect shift away from GenServer.
  """

  import Rx.Internal.ValidObservable

  # @doc ~S"""
  # Creates an observable from the given function.
  #
  # The function takes a single parameter (`next`) which is itself a function that
  # may be called to produce values. If the function exits via an error, the Observable
  # terminates with the same error after producing any values seen up to that point.
  # If the function exits normally, the Observable terminates with "done" state.
  #
  # This approach should be used for demonstration and lightweight purposes mostly
  # since it abuses the GenServer interface by inverting control and disrespecting
  # the demand requests.
  #
  # ## Examples
  #   iex> Rx.Observable.create(fn next ->
  #   ...>   next.("Hello")
  #   ...>   next.("World")
  #   ...> end)
  #   ...> |> Enum.to_list()
  #   ["Hello", "World"]
  # """
  # TODO: Reimplement.
  # def create(fun) when is_function(fun, 1) do
  #   %__MODULE__{reversed_stages: [%Rx.Observable.CreateStage{fun: fun}]}
  # end

  # @doc ~S"""
  # Creates an observable that emits no items and immediately terminates normally.
  #
  # ## Examples
  #   iex> Rx.Observable.empty()
  #   ...> |> Enum.to_list()
  #   []
  #
  #   # iex> Rx.Observable.empty()
  #   # ...> |> Rx.Observable.to_notifications()
  #   # ...> |> Enum.to_list()
  #   # [:done]
  # """
  # TODO: Reimplement.
  # def empty, do:
  #   %__MODULE__{reversed_stages: [%Rx.Observable.EmptyStage{}]}

  # @doc ~S"""
  # Creates an observable that emits no items and terminates with an error.
  #
  # The function takes a single parameter which is the error to raise. This error
  # is thrown immediately upon subscription.
  #
  # The error value should be a normal value, not an exception struct.
  #
  # ## Examples
  #   iex> Rx.Observable.throw("testing error")
  #   ...> |> Rx.Observable.to_notifications()
  #   ...> |> Enum.to_list()
  #   [{:error, "testing error"}]
  # """
  # TODO: Reimplement.
  # def throw(err) do
  #   %__MODULE__{reversed_stages: [%Rx.Observable.ThrowStage{message: err}]}
  # end

  @doc ~S"""
  Converts each notification to a tuple (or the `:done` atom) describing the notification.

  The mapping is done as follows:

  * normal value -> `{:next, (value)}`
  * error termination -> `{:error, (reason)}`
  * normal termination -> `:done`

  ## Examples
    # TODO: Reimplement.
    # iex> Rx.Observable.create(fn next ->
    # ...>   next.("Hello")
    # ...>   next.("World")
    # ...> end)
    # ...> |> Rx.Observable.to_notifications()
    # ...> |> Enum.to_list()
    # [{:next, "Hello"}, {:next, "World"}, :done]

    # iex> Rx.Observable.create(fn next ->
    # ...>   next.("Hello")
    # ...>   next.("World")
    # ...>   raise Rx.Error, message: "foo"
    # ...> end)
    # ...> |> Rx.Observable.to_notifications()
    # ...> |> Enum.to_list()
    # [{:next, "Hello"}, {:next, "World"}, {:error, "foo"}]

    # iex> Rx.Observable.create(fn next ->
    # ...>   next.("Hello")
    # ...>   next.("World")
    # ...>   raise "foo"  # raises RuntimeError instead
    # ...> end)
    # ...> |> Rx.Observable.to_notifications()
    # ...> |> Enum.to_list()
    # [{:next, "Hello"}, {:next, "World"}, {:error, %RuntimeError{message: "foo"}}]
  """
  def to_notifications(observable), do:
    %Rx.Observable.ToNotifications{source: enforce(observable)}

  # def start(%__MODULE__{reversed_stages: reversed_stages} = _observable) do
  #   start_stages(reversed_stages)
  #   # TODO: Move this into a materialize module a la Flow?
  # end
  #
  # defp start_stages([%{__struct__: module} = producer_stage]) do
  #   # TODO: Should this be start_link?
  #   module.start(producer_stage, :producer)
  # end
  #
  # defp start_stages([%{__struct__: module} = consumer_stage | more_stages]) do
  #   {:ok, my_producer} = start_stages(more_stages)
  #   {:ok, my_consumer} = module.start(consumer_stage, :producer_consumer)  # start_link?
  #   GenStage.sync_subscribe(my_consumer, to: my_producer, cancel: :transient)
  #   {:ok, my_consumer}
  # end
  #
  # defp add_stage(%__MODULE__{reversed_stages: []} = _observable, _stage, fname) do
  #   raise """
  #   Rx.Observable.#{fname} can not be used here.
  #
  #   Try using Rx.Observable.create or some other function that creates a valid
  #   source/producer Observable first.
  #   """
  # end
  #
  # defp add_stage(%__MODULE__{reversed_stages: reversed_stages} = observable,
  #                stage, _fname)
  # do
  #   reversed_stages = [stage | reversed_stages]
  #   %{observable | reversed_stages: reversed_stages}
  # end
  #
  # defp add_stage(not_observable, _stage, fname) do
  #   raise """
  #   Rx.Observable.#{fname} can not be used here.
  #
  #   The first argument ("observable") is not actually an Rx.Observable.
  #
  #   #{inspect not_observable}
  #   """
  # end
  #
  # defimpl Enumerable do
  #   def reduce(observable, acc, fun) do
  #     case Rx.Observable.start(observable) do
  #       {:ok, pid} ->
  #         GenStage.stream([{pid, cancel: :transient}]).(acc, fun)
  #       {:error, reason} ->
  #         exit({reason, {__MODULE__, :reduce, [observable, acc, fun]}})
  #     end
  #   end
  #
  #   def count(_observable) do
  #     {:error, __MODULE__}
  #   end
  #
  #   def member?(_observable, _value) do
  #     {:error, __MODULE__}
  #   end
  # end
end
