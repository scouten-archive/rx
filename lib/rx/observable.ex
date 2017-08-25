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
  to think of RxElixir as a factory for `GenServer`-like processes which work together
  to implement the desired computation.

  Note, however, that Observables do not run in their own processes unless explicitly
  configured to do so. (TODO: How? Not yet possible.)
  """

  import Rx.Internal.ValidObservable

  @doc ~S"""
  Creates an Observable from the given Enumerable.

  ## Examples

  (Yes, this is an absurd example.)

    iex> Rx.Observable.from_enumerable(["Hello", "World"])
    ...> |> Enum.to_list()
    ["Hello", "World"]
  """
  def from_enumerable(e), do: %Rx.Observable.FromEnumerable{source: e}

  @doc ~S"""
  Creates an Observable that emits a sequence of numbers within a specified range.

  ## Examples
    iex> Rx.Observable.range(1, 4)
    ...> |> Enum.to_list()
    [1, 2, 3, 4]

    iex> Rx.Observable.range(6, 4)
    ...> |> Enum.to_list()
    [6, 7, 8, 9]

    iex> Rx.Observable.range(1, 0)
    ...> |> Enum.to_list()
    []
  """
  def range(start, 0) when is_integer(start), do:
    %Rx.Observable.Empty{}

  def range(start, count)
  when is_integer(start) and is_integer(count) and count > 0, do:
    %Rx.Observable.FromEnumerable{source: start..(start + count - 1)}

  @doc ~S"""
  Creates an Observable from the given function.

  The function takes a single parameter (`next`) which is itself a function that
  may be called to produce values. If the function exits via an error, the Observable
  terminates with the same error after producing any values seen up to that point.
  If the function exits normally, the Observable terminates with "done" state.

  Note that the function is executed in an independent process spawned when the
  Observable receives a subscription.

  ## Examples
    iex> Rx.Observable.create(fn next ->
    ...>   next.("Hello")
    ...>   next.("World")
    ...> end)
    ...> |> Enum.to_list()
    ["Hello", "World"]
  """
  def create(fun) when is_function(fun, 1), do: %Rx.Observable.Create{fun: fun}

  @doc ~S"""
  Creates an Observable that emits no items and immediately terminates normally.

  ## Examples
    iex> Rx.Observable.empty()
    ...> |> Enum.to_list()
    []

    iex> Rx.Observable.empty()
    ...> |> Rx.Observable.to_notifications()
    ...> |> Enum.to_list()
    [:done]
  """
  def empty, do: %Rx.Observable.Empty{}

  @doc ~S"""
  Creates an Observable that emits no items and terminates with an error.

  The function takes a single parameter which is the error to raise. This error
  is thrown immediately upon subscription.

  The error value should be a normal value, not an exception struct.

  ## Examples
    iex> Rx.Observable.throw("testing error")
    ...> |> Rx.Observable.to_notifications()
    ...> |> Enum.to_list()
    [{:error, "testing error"}]
  """
  def throw(error), do: %Rx.Observable.Throw{error: error}

  @doc ~S"""
  Converts each notification to a tuple (or the `:done` atom) describing the notification.

  The mapping is done as follows:

  * normal value -> `{:next, (value)}`
  * error termination -> `{:error, (reason)}`
  * normal termination -> `:done`

  ## Examples
    iex> Rx.Observable.create(fn next ->
    ...>   next.("Hello")
    ...>   next.("World")
    ...> end)
    ...> |> Rx.Observable.to_notifications()
    ...> |> Enum.to_list()
    [{:next, "Hello"}, {:next, "World"}, :done]

    iex> Rx.Observable.create(fn next ->
    ...>   next.("Hello")
    ...>   next.("World")
    ...>   raise Rx.Error, message: "foo"
    ...> end)
    ...> |> Rx.Observable.to_notifications()
    ...> |> Enum.to_list()
    [{:next, "Hello"}, {:next, "World"}, {:error, "foo"}]

    iex> Rx.Observable.create(fn next ->
    ...>   next.("Hello")
    ...>   next.("World")
    ...>   raise "foo"  # raises RuntimeError instead
    ...> end)
    ...> |> Rx.Observable.to_notifications()
    ...> |> Enum.to_list()
    [{:next, "Hello"}, {:next, "World"}, {:error, %RuntimeError{message: "foo"}}]
  """
  def to_notifications(observable), do:
    %Rx.Observable.ToNotifications{source: enforce(observable)}
end
