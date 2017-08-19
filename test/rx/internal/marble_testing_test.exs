defmodule MarbleTestingTest do
  use ExUnit.Case, async: true

  import MarbleTesting
  doctest MarbleTesting

  describe "cold/2" do
    source = cold      "-a-b-|", values: %{a: 1, b: 2}
    expected = marbles "-a-b-|", values: %{a: 1, b: 2}
    {notifs, _subscriptions} = observe(source)

    assert notifs == expected

    assert notifs == [
      {10, :next, 1},
      {30, :next, 2},
      {50, :done}
    ]
  end

  describe "marbles/2" do
    test "raises if marble string has unsubscription marker (!)" do
      assert_raise ArgumentError,
        ~S/conventional marble diagrams cannot have the unsubscription marker "!"/,
        fn -> MarbleTesting.marbles("---!---") end
    end
  end

  describe "marbles_as_subscriptions/1" do
    test "raises if multiple subscription points found" do
      assert_raise ArgumentError,
        ~S/found a second subscription point '^' in a subscription marble diagram. / <>
          "There can only be one.",
        fn -> MarbleTesting.marbles_as_subscriptions("---^---^--") end
    end

    test "raises if multiple unsubscription points found" do
      assert_raise ArgumentError,
        ~S/found a second unsubscription point '!' in a subscription marble diagram. / <>
         "There can only be one.",
        fn -> MarbleTesting.marbles_as_subscriptions("---^-!-!--") end
    end

    test "raises if invalid marbles found" do
      assert_raise ArgumentError,
        ~S/found an invalid character 'x' in subscription marble diagram./,
        fn -> MarbleTesting.marbles_as_subscriptions("---^--x--") end
    end
  end
end
