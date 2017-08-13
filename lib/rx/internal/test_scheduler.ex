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

  * `-` or space: Nothing happens in this frame.
  * `|`: The observable terminates with `:done` status in this frame.
  * `^`: The observer subscribes at this time point. All notifications before this
    are ignored. Time begins at time zero at this point.
  * `(` and `)`: Groups multiple events such that they all occur at the same time.
  * Any other character: The observable generates a `:next` notification
    during this frame. The value is the character *unless* overridden by a
    corresponding entry in the `values` option.

  ## Options

  If provided, the `options` keyword list is interpreted as follows:

  * `values:` is a map which can be used to replace a single-character `:next`
    notification with any other value. See examples below.

  ## Examples

  Simplest case (without options):

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|")
  [
    { 70, :next, "a"},
    {110, :next, "b"},
    {150, :done}
  ]
  ```

  Using `values` option to replace placeholder values with real values:

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---|",
  ...>                                         values: %{a: "ABC", b: "BCD"})
  [
    { 70, :next, "ABC"},
    {110, :next, "BCD"},
    {150, :done}
  ]
  ```

  Trailing spaces permitted:

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("--a--b--|   ",
  ...>                                         values: %{a: "A", b: "B"})
  [
    {20, :next, "A"},
    {50, :next, "B"},
    {80, :done}
  ]
  ```

  Explicit subscription start point:

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("---^---a---b---|",
  ...>                                         values: %{a: "A", b: "B"})
  [
    { 40, :next, "A"},
    { 80, :next, "B"},
    {120, :done}
  ]
  ```

  Marble string that ends with an error:

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("-------a---b---#",
  ...>                                         values: %{a: "A", b: "B"},
  ...>                                         error: "omg error!")
  [
    { 70, :next, "A"},
    {110, :next, "B"},
    {150, :error, "omg error!"}
  ]
  ```

  Grouped values occur at the same time:

  ```
  iex> Rx.Internal.TestScheduler.parse_marbles("---(abc)-e-")
  [
    {30, :next, "a"},
    {30, :next, "b"},
    {30, :next, "c"},
    {50, :next, "e"}
  ]
  ```
  """
  def parse_marbles(marbles, options \\ []) do
    if String.contains?(marbles, "!") do
      raise ArgumentError,
            ~S/conventional marble diagrams cannot have the unsubscription marker "!"/
    end

    values = Keyword.get(options, :values, %{})
    error = Keyword.get(options, :error, "error")
    acc = %{rnotifs: [], time: 0, values: values, error: error, in_group?: false}

    marbles
    |> String.codepoints()
    |> Enum.reduce(acc, &parse_marble_char/2)
    |> Map.get(:rnotifs)
    |> Enum.reverse()
  end

  defp parse_marble_char("-", acc), do: add_idle_marble(acc)
  defp parse_marble_char(" ", acc), do: add_idle_marble(acc)
  defp parse_marble_char("^", acc), do:
    maybe_advance_time(%{acc | rnotifs: [], time: 0})
  defp parse_marble_char("(", %{in_group?: false} = acc), do:
    %{acc | in_group?: true}
  defp parse_marble_char(")", %{in_group?: true} = acc), do:
    maybe_advance_time(%{acc | in_group?: false})
  defp parse_marble_char("|", acc), do: add_notif_marble(:done, acc)
  defp parse_marble_char("#", %{error: error} = acc), do:
    add_notif_marble(:error, error, acc)
  defp parse_marble_char(char, %{values: values} = acc), do:
    add_notif_marble(:next, Map.get(values, String.to_atom(char), char), acc)

  defp add_idle_marble(acc), do: maybe_advance_time(acc)

  defp add_notif_marble(:next, value, %{time: time} = acc), do:
    add_notif_marble({time, :next, value}, acc)
  defp add_notif_marble(:error, error, %{time: time} = acc), do:
    add_notif_marble({time, :error, error}, acc)
  defp add_notif_marble(:done, %{time: time} = acc), do:
    add_notif_marble({time, :done}, acc)

  defp add_notif_marble(notif, %{rnotifs: rnotifs} = acc), do:
    maybe_advance_time(%{acc | rnotifs: [notif | rnotifs]})

  defp maybe_advance_time(%{in_group?: true} = acc), do: acc
  defp maybe_advance_time(%{time: old_time, in_group?: false} = acc), do:
    %{acc | time: old_time + @frame_time_factor}
end
