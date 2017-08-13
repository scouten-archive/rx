defmodule Rx.Internal.TestSchedulerTest do
  use ExUnit.Case, async: true

  import Rx.Internal.TestScheduler
  doctest Rx.Internal.TestScheduler

  describe "parse_marbles/2" do
    test "throws if marble string has unsubscription marker (!)" do
      assert_raise ArgumentError,
        "conventional marble diagrams cannot have the unsubscription marker \"!\"",
        fn -> parse_marbles("---!---") end
    end
  end
end
