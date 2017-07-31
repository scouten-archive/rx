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
  """

  defstruct stages: []

  @doc ~S"""
  Creates an observable from the given function.

  The function takes a single parameter (`next`) which is itself a function that
  may be called to produce values. If the function exits via an error, the Observable
  terminates with the same error after producing any values seen up to that point.
  If the function exits normally, the Observable terminates with "done" state.

  This approach should be used for demonstration and lightweight purposes mostly
  since it abuses the GenServer interface by inverting control and disrespecting
  the demand requests.

  ## Examples
    iex> Rx.Observable.create(fn next ->
    ...>   next.("Hello")
    ...>   next.("World")
    ...> end)
    ...> |> Enum.to_list()
    ["Hello", "World"]

    # TO DO: Create an error example.
  """
  def create(fun) when is_function(fun, 1) do
    %__MODULE__{stages: [%Rx.Observable.CreateStage{fun: fun}]}
  end

  def start(%__MODULE__{stages: [%{__struct__: module} = stage]} = _observable) do
    # TODO: Handle chains of Observables.
    # TODO: Should this be start_link?
    # TODO: Move this into a materialize module a la Flow?

    module.start(stage, :producer)
  end

  defimpl Enumerable do
    def reduce(observable, acc, fun) do
      case Rx.Observable.start(observable) do
        {:ok, pid} ->
          GenStage.stream([{pid, cancel: :transient}]).(acc, fun)
        {:error, reason} ->
          exit({reason, {__MODULE__, :reduce, [observable, acc, fun]}})
      end
    end

    def count(_observable) do
      {:error, __MODULE__}
    end

    def member?(_observable, _value) do
      {:error, __MODULE__}
    end
  end
end
