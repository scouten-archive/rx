defprotocol Rx.Internal.SubjectImplementation do
  @moduledoc false
  # Used as a "duck-typing" marker to signal that a given module should be considered
  # a valid Rx.Subject implementation.

  def is_subject(o)
end

defmodule Rx.Internal.ValidSubject do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Rx.Internal.ValidObservable

      defimpl Rx.Internal.SubjectImplementation do
        def is_subject(_), do: true
      end
    end
  end

  def assert_is_subject(s, fun, arg \\ nil) do
    try do
      true = Rx.Internal.SubjectImplementation.is_subject(s)
    rescue
      Protocol.UndefinedError -> raise_not_subject(s, fun, arg)
    end
    s
  end

  def assert_is_subject(s, module, {fun, arity}, arg), do:
    assert_is_subject(s, "#{inspect module}.#{fun}/#{arity}", arg)

  defp raise_not_subject(s, fun, arg) do
    arg_phrase = if arg == nil, do: "", else: " argument #{arg}"
    raise ArgumentError, ~s"""
    #{fun}#{arg_phrase} received a value that is not a valid Rx.Subject.

    #{inspect s}

    """
  end

  defmacro enforce(s) do
    quote do
      assert_is_subject(unquote(s), __ENV__.module, __ENV__.function, nil)
    end
  end

  defmacro enforce(s, arg_name) do
    quote do
      assert_is_subject(unquote(s), __ENV__.module, __ENV__.function,
                        to_string(unquote(arg_name)))
    end
  end
end
