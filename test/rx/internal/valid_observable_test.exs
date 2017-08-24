defmodule Rx.Internal.ValidObservableTest do
  use ExUnit.Case, async: true

  import Rx.Internal.ValidObservable

  describe "assert_is_observable/3" do
    test "accepts a valid Observable" do
      assert_is_observable(%MarbleTesting.ColdObservable{}, "x")
    end

    test "rejects an invalid Observable" do
      assert_raise ArgumentError,
        """
        test_fn received a value that is not a valid Rx.Observable.

        %{duck_typing: :not_an_observable}

        """,
        fn ->
          assert_is_observable(%{duck_typing: :not_an_observable}, "test_fn")
        end
    end

    test "rejects an invalid Observable with arg name" do
      assert_raise ArgumentError,
        """
        test_fn argument foo received a value that is not a valid Rx.Observable.

        %{duck_typing: :not_an_observable}

        """,
        fn ->
          assert_is_observable(%{duck_typing: :not_an_observable}, "test_fn", "foo")
        end
    end
  end

  describe "enforce/1" do
    test "accepts a valid Observable" do
      o = %MarbleTesting.ColdObservable{}
      assert call_enforce_1(o) == o
    end

    test "rejects an invalid Observable" do
      assert_raise ArgumentError,
        "Rx.Internal.ValidObservableTest.call_enforce_1/1 " <>
        """
        received a value that is not a valid Rx.Observable.

        %{observable: :nope}

        """,
        fn -> call_enforce_1(%{observable: :nope}) end
    end
  end

  describe "enforce/2" do
    test "accepts a valid Observable" do
      call_enforce_2(%MarbleTesting.ColdObservable{}, "blah")
    end

    test "rejects an invalid Observable" do
      assert_raise ArgumentError,
        "Rx.Internal.ValidObservableTest.call_enforce_2/2 argument blah " <>
        """
        received a value that is not a valid Rx.Observable.

        %{observable: :nope}

        """,
        fn -> call_enforce_2(%{observable: :nope}, "blah") end
    end
  end

  defp call_enforce_1(o), do: enforce(o)
  defp call_enforce_2(o, arg_name), do: enforce(o, arg_name)
end
