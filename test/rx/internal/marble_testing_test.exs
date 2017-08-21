defmodule MarbleTestingTest do
  use ExUnit.Case, async: true

  import MarbleTesting
  doctest MarbleTesting

  describe "cold/2" do
    test "makes it easy to write marble tests" do
      source = cold      "-a-b-|", values: %{a: 1, b: 2}
      expected = marbles "-a-b-|", values: %{a: 1, b: 2}
      subs = sub_marbles "^----!"

      assert observe(source) == expected
      assert subscriptions(source) == subs
    end

    test "raises if cold observable has subscription offset" do
      assert_raise ArgumentError,
        ~S/cold observable cannot have subscription offset "^"/,
        fn -> cold "--^-a-b-|" end
    end

    test "raises if cold observable has unsubscription marker" do
      assert_raise ArgumentError,
        ~S/cold observable cannot have unsubscription marker "!"/,
        fn -> cold "-a-b-!" end
    end
  end

  describe "marbles/2" do
    test "raises if marble string has unsubscription marker (!)" do
      assert_raise ArgumentError,
        ~S/conventional marble diagrams cannot have the unsubscription marker "!"/,
        fn -> marbles("---!---") end
    end
  end

  describe "sub_marbles/1" do
    test "raises if multiple subscription points found" do
      assert_raise ArgumentError,
        ~S/found a second subscription point '^' in a subscription marble diagram. / <>
          "There can only be one.",
        fn -> sub_marbles("---^---^--") end
    end

    test "raises if multiple unsubscription points found" do
      assert_raise ArgumentError,
        ~S/found a second unsubscription point '!' in a subscription marble diagram. / <>
         "There can only be one.",
        fn -> sub_marbles("---^-!-!--") end
    end

    test "raises if invalid marbles found" do
      assert_raise ArgumentError,
        ~S/found an invalid character 'x' in subscription marble diagram./,
        fn -> sub_marbles("---^--x--") end
    end
  end
end
