defmodule Rx.Subject do
  @moduledoc ~S"""
  TODO: Write documentation for Subject.
  """

  import Rx.Internal.ValidSubject

  @doc ~S"""
  TODO: Write documentation.
  """
  def create, do: %Rx.Subject.Create{pid: self(), ref: make_ref()}

  def next(subject, value) do
    {pid, ref} = enforce_sendable_subject(subject, "next")
    send(pid, {:next, ref, value})
  end

  def done(subject) do
    {pid, ref} = enforce_sendable_subject(subject, "done")
    send(pid, {:done, ref})
  end

  # def error(subject, error) do ...

  defp enforce_sendable_subject(subject, f) do
    enforce(subject)
    try do
      %{pid: pid, ref: ref} = subject
      {pid, ref}
    rescue
      MatchError ->
        raise ArgumentError,
              ~s"""
              Rx.Subject.#{f} received a Subject that can not receive arbitrary messages.

              #{inspect subject}

              Try using a subject created by Rx.Subject.create.

              """
    end
  end
end
