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

    # it('should parse a marble string with an error', () => {
    #   const result = TestScheduler.parseMarbles('-------a---b---#', { a: 'A', b: 'B' }, 'omg error!');
    #   expect(result).deep.equal([
    #     { frame: 70, notification: Notification.createNext('A') },
    #     { frame: 110, notification: Notification.createNext('B') },
    #     { frame: 150, notification: Notification.createError('omg error!') }
    #   ]);
    # });
    #
    # it('should default in the letter for the value if no value hash was passed', () => {
    #   const result = TestScheduler.parseMarbles('--a--b--c--');
    #   expect(result).deep.equal([
    #     { frame: 20, notification: Notification.createNext('a') },
    #     { frame: 50, notification: Notification.createNext('b') },
    #     { frame: 80, notification: Notification.createNext('c') },
    #   ]);
    # });
    #
    # it('should handle grouped values', () => {
    #   const result = TestScheduler.parseMarbles('---(abc)---');
    #   expect(result).deep.equal([
    #     { frame: 30, notification: Notification.createNext('a') },
    #     { frame: 30, notification: Notification.createNext('b') },
    #     { frame: 30, notification: Notification.createNext('c') }
    #   ]);
    # });
  end
end
