defprotocol Rx.Internal.ObservableImplementation do
  @moduledoc false
  # Used as a "duck-typing" marker to signal that a given module should be considered
  # a valid Rx.Observable implementation.

  def is_observable(o)
end

defmodule Rx.Internal.ValidObservable do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      defimpl Rx.Internal.ObservableImplementation do
        def is_observable(_), do: true
      end
    end
  end

  def assert_is_observable(o, fun, arg \\ nil) do
    try do
      true = Rx.Internal.ObservableImplementation.is_observable(o)
    rescue
      Protocol.UndefinedError -> raise_not_observable(o, fun, arg)
    end
    o
  end

  def assert_is_observable(o, module, {fun, arity}, arg), do:
    assert_is_observable(o, "#{inspect module}.#{fun}/#{arity}", arg)

  defp raise_not_observable(o, fun, arg) do
    arg_phrase = if arg == nil, do: "", else: " argument #{arg}"
    raise ArgumentError, ~s"""
    #{fun}#{arg_phrase} received a value that is not a valid Rx.Observable.

    #{inspect o}

    """
  end

  defmacro enforce(o) do
    quote do
      assert_is_observable(unquote(o), __ENV__.module, __ENV__.function, nil)
    end
  end

  defmacro enforce(o, arg_name) do
    quote do
      assert_is_observable(unquote(o), __ENV__.module, __ENV__.function,
                           to_string(unquote(arg_name)))
    end
  end
end
