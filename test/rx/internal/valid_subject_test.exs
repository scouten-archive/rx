defmodule Rx.Internal.ValidSubjectTest do
  use ExUnit.Case, async: true

  import Rx.Internal.ValidSubject

  describe "assert_is_subject/3" do
    test "accepts a valid Subject" do
      assert_is_subject(%MarbleTesting.HotObservable{}, "x")
    end

    test "rejects a valid Observable that is not also a Subject" do
      assert_raise ArgumentError,
        """
        x received a value that is not a valid Rx.Subject.

        %MarbleTesting.ColdObservable{log_target_pid: nil, notifs: nil, started_by: nil}

        """,
        fn ->
          assert_is_subject(%MarbleTesting.ColdObservable{}, "x")
        end
    end

    test "rejects an invalid Subject" do
      assert_raise ArgumentError,
        """
        test_fn received a value that is not a valid Rx.Subject.

        %{duck_typing: :not_a_subject}

        """,
        fn ->
          assert_is_subject(%{duck_typing: :not_a_subject}, "test_fn")
        end
    end

    test "rejects an invalid Subject with arg name" do
      assert_raise ArgumentError,
        """
        test_fn argument foo received a value that is not a valid Rx.Subject.

        %{duck_typing: :not_a_subject}

        """,
        fn ->
          assert_is_subject(%{duck_typing: :not_a_subject}, "test_fn", "foo")
        end
    end
  end

  describe "enforce/1" do
    test "accepts a valid Subject" do
      s = %MarbleTesting.HotObservable{}
      assert call_enforce_1(s) == s
    end

    test "rejects a valid Observable" do
      o = %MarbleTesting.ColdObservable{}
      assert_raise ArgumentError,
        """
        Rx.Internal.ValidSubjectTest.call_enforce_1/1 received a value that is not a valid Rx.Subject.

        %MarbleTesting.ColdObservable{log_target_pid: nil, notifs: nil, started_by: nil}

        """,
        fn ->
          call_enforce_1(o)
        end
    end

    test "rejects an invalid Observable" do
      assert_raise ArgumentError,
        "Rx.Internal.ValidSubjectTest.call_enforce_1/1 " <>
        """
        received a value that is not a valid Rx.Subject.

        %{observable: :nope}

        """,
        fn -> call_enforce_1(%{observable: :nope}) end
    end
  end

  describe "enforce/2" do
    test "accepts a valid Observable" do
      call_enforce_2(%MarbleTesting.HotObservable{}, "blah")
    end

    test "rejects an invalid Observable" do
      assert_raise ArgumentError,
        "Rx.Internal.ValidSubjectTest.call_enforce_2/2 argument blah " <>
        """
        received a value that is not a valid Rx.Subject.

        %{observable: :nope}

        """,
        fn -> call_enforce_2(%{observable: :nope}, "blah") end
    end
  end

  defp call_enforce_1(o), do: enforce(o)
  defp call_enforce_2(o, arg_name), do: enforce(o, arg_name)
end
