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

  defstruct mumble: true

  @doc ~S"""
  Creates an observable from the given subscription function.

  ## Examples

    iex> Rx.Observable.create(fn o ->
    ...>   Rx.Observer.next(o, "Hello")
    ...>   Rx.Observer.next(o, "World")
    ...> end)
    ...> |> Rx.Observable.to_list()
    {"Hello", "World"}
  """
  def create(fun) when is_function(fun, 1) do
    %__MODULE__{mumble: true}
  end

  def subscribe(next) when is_function(next, 1) do
    :not_yet_implemented
  end

  def to_list(%__MODULE__{} = _o) do
    :not_yet_implemented
  end
end
