defmodule Rx.Internal.TestScheduler do
  @moduledoc ~S"""
  Coordinates the running of tests across multiple OTP processes so that
  tests can run quickly and predictably.

  TODO: Write more documentation.
  """

  @frame_time_factor 10

  @doc ~S"""
  Converts a string containing a marble diagram of notifications into a sequence
  of expected notifications.

  Each character in a marble diagram represents 10 "units" of time, also known as
  a "frame." Characters are parsed as follows:

  * `-` or ` `: Nothing happens in this frame.
  * `|`: The observable terminates with `:done` status in this frame.
  * Any other character: The observable generates a `:next` notification
    during this frame. The value is the character *unless* overridden by a
    corresponding entry in the `values` option.

  ## Options

  If provided, the `options` keyword list is interpreted as follows:

  * `values:` is a map which can be used to replace a single-character `:next`
    notification with any other value. See examples below.

  ## Examples
    # Simplest case (without options):

    iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|")
    [
      { 70, :next, "a"},
      {110, :next, "b"},
      {150, :done}
    ]

    # Using `values` option to replace placeholder values with real values:

    iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|",
    ...>                                         values: %{a: "ABC", b: "BCD"})
    [
      { 70, :next, "ABC"},
      {110, :next, "BCD"},
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
    acc = %{rnotifs: [], time: 0, values: values}

    String.codepoints(marbles)
    |> Enum.reduce(acc, &parse_marble_char/2)
    |> Map.get(:rnotifs)
    |> Enum.reverse()
  end

  defp parse_marble_char("-", acc), do: add_idle_marble(acc)
  defp parse_marble_char(" ", acc), do: add_idle_marble(acc)
  defp parse_marble_char("|", acc), do: add_notif_marble(:done, acc)
  defp parse_marble_char(char, %{values: values} = acc), do:
    add_notif_marble(:next, Map.get(values, String.to_atom(char), char), acc)

  defp add_idle_marble(%{time: time} = acc), do:
    %{acc | time: time + @frame_time_factor}

  defp add_notif_marble(:next, value, %{time: time} = acc), do:
    add_notif_marble({time, :next, value}, acc)
  defp add_notif_marble(:done, %{time: time} = acc), do:
    add_notif_marble({time, :done}, acc)

  defp add_notif_marble(notif, %{rnotifs: rnotifs, time: time} = acc), do:
    %{acc | rnotifs: [notif | rnotifs], time: time + @frame_time_factor}
end
