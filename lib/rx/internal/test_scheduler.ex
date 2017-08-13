defmodule Rx.Internal.TestScheduler do
  @moduledoc ~S"""
  Coordinates the running of tests across multiple OTP processes so that
  tests can run quickly and predictably.

  TODO: Write more documentation.
  """

  @frame_time_factor 10
    # each character in a marble diagram represents 10 "units" of time

  @doc ~S"""
  Converts a string containing a marble diagram of notifications into a sequence
  of expected notifications.

  TODO: Write more documentation.

  ## Examples
    # Simplest case (without options):

    iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|")
    [
      { 70, :next, "a"},
      {110, :next, "b"},
      {150, :done}
    ]

    # Using `values` option to replace placeholders with real values:

    iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|",
    ...>                                         values: %{a: "A", b: "B"})
    [
      { 70, :next, "A"},
      {110, :next, "B"},
      {150, :done}
    ]

    # Trailing spaces permitted:

    iex> Rx.Internal.TestScheduler.parse_marbles("--a--b--|   ",
    ...>                                         values: %{a: "A", b: "B"})
    [
      {20, :next, "A"},
      {50, :next, "B"},
      {80, :done}
    ]
  """
  def parse_marbles(marbles, options \\ []) do
    if String.contains?(marbles, "!") do
      raise ArgumentError,
            "conventional marble diagrams cannot have the unsubscription marker \"!\""
    end

    values = Keyword.get(options, :values, %{})
    acc = {[], 0, values}

    String.codepoints(marbles)
    |> Enum.reduce(acc, &parse_marble_char/2)
    |> elem(0)
    |> Enum.reverse()
  end

  defp parse_marble_char("-", acc), do: add_idle_marble(acc)
  defp parse_marble_char(" ", acc), do: add_idle_marble(acc)
  defp parse_marble_char("|", acc), do: add_notif_marble(:done, acc)
  defp parse_marble_char(char, {_, _, values} = acc), do:
    add_notif_marble(:next, Map.get(values, String.to_atom(char), char), acc)

  defp add_idle_marble({existing_notifs, time, values}), do:
    {existing_notifs, time + @frame_time_factor, values}

  defp add_notif_marble(:next, value, {existing_notifs, time, values}), do:
    {[{time, :next, value} | existing_notifs], time + @frame_time_factor, values}
  defp add_notif_marble(:done, {existing_notifs, time, values}), do:
    {[{time, :done} | existing_notifs], time + @frame_time_factor, values}
end
