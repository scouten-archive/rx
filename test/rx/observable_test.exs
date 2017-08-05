defmodule Rx.ObservableTest do
  use ExUnit.Case, async: true

  doctest Rx.Observable

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
end
