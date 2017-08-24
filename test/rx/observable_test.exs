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

  # @empty_observable %OLD.Rx.Observable{} # not a supported use case!
  #
  # describe "add_stage/3 (internal)" do
  #   test "won't add stage to otherwise empty Observable" do
  #     assert_raise RuntimeError, fn ->
  #       OLD.Rx.Observable.to_notifications(@empty_observable)
  #     end
  #   end
  #
  #   test "won't add stage to a non-Observable" do
  #     assert_raise RuntimeError, fn ->
  #       OLD.Rx.Observable.to_notifications("not an Observable")
  #     end
  #   end
  # end
  #
  # @crash_observable %OLD.Rx.Observable{reversed_stages: [%__MODULE__.CrashStage{}]}
  #
  # describe "to_list/1 (via Enumerable)" do
  #   test "crashes if source stream crashes on construction" do
  #     capture_log(fn ->
  #       assert {{%RuntimeError{message: "test failure in init fn"}, _}, _} =
  #         catch_exit(Enum.to_list(@crash_observable))
  #     end)
  #   end
  # end
end
