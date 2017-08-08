defmodule Rx.Error do
  @moduledoc ~S"""
  This error should be raised to signal an error exit from any Observable.

  Rx code will strip away the exception code and pass simply the `message`
  value in any error tuple reported.

  Any *other* exception that is raised will be passed through as is.
  """

  defexception message: "No error message provided."
end
