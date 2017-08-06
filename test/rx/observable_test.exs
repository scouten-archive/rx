defmodule Rx.ObservableTest do
  use ExUnit.Case, async: true

  doctest Rx.Observable

  import ExUnit.CaptureLog

  @empty_observable %Rx.Observable{} # not a supported use case!

  describe "add_stage/3 (internal)" do
    test "won't add stage to otherwise empty Observable" do
      assert_raise RuntimeError, fn ->
        Rx.Observable.to_notifications(@empty_observable)
      end
    end

    test "won't add stage to a non-Observable" do
      assert_raise RuntimeError, fn ->
        Rx.Observable.to_notifications("not an Observable")
      end
    end
  end

  @crash_observable %Rx.Observable{reversed_stages: [%CrashStage{}]}

  describe "to_list/1 (via Enumerable)" do
    test "crashes if source stream crashes on construction" do
      capture_log(fn ->
        assert {{%RuntimeError{message: "test failure in init fn"}, _}, _} =
          catch_exit(Enum.to_list(@crash_observable))
      end)
    end
  end
end
