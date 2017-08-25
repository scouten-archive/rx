defmodule Rx.ObservableTest do
  use ExUnit.Case, async: true

  import MarbleTesting

  doctest Rx.Observable

  # import ExUnit.CaptureLog

  describe "to_notifications/1" do
    test "converts notifications into tuples" do
      source = cold      "-a-b-|", values: %{a: "hello", b: "world"}
      expected = marbles "-a-b-(c|)", values: %{a: {:next, "hello"},
                                                b: {:next, "world"},
                                                c: :done}
      subs = sub_marbles "^----!"

      assert observe(source |> Rx.Observable.to_notifications()) == expected
      assert subscriptions(source) == subs
    end
  end

  describe "to_list/1 (via Enumerable)" do
    test "converts the :next notifications from an Observable to a list" do
      source = cold "-a-b-c-|"
      assert Enum.to_list(source) == ["a", "b", "c"]
    end
  end
end
