defmodule Rx.ObservableTest do
  use ExUnit.Case, async: true

  import MarbleTesting

  alias Rx.Observable, as: Rx

  # doctest Rx.Observable  # TODO: Restore this.

  # import ExUnit.CaptureLog

  describe "to_notifications/1" do
    test "converts notifications into tuples" do
      source = cold      "-a-b-|", values: %{a: "hello", b: "world"}
      expected = marbles "-a-b-(c|)", values: %{a: {:next, "hello"},
                                                b: {:next, "world"},
                                                c: :done}
      subs = sub_marbles "^----!"

      assert observe(source |> Rx.to_notifications()) == expected
      assert subscriptions(source) == subs
    end
  end

  # describe "to_list/1 (via Enumerable)" do
  #   test "converts the :next notifications from an Observable to a list" do
  #     source = cold "-a-b-c-|"
  #     assert Enum.to_list(source) == ["a", "b", "c"]
  #   end
  #
  #   test "crashes if source stream crashes on construction" do
  #     capture_log(fn ->
  #       assert {{%RuntimeError{message: "test failure in init fn"}, _}, _} =
  #         catch_exit(Enum.to_list(@crash_observable))
  #     end)
  #   end
  # end
end
