defmodule Rx.Observable.TakeTest do
  # credo:disable-for-this-file Credo.Check.Readability.SinglePipe

  use ExUnit.Case, async: true

  import MarbleTesting
  import Rx.Observable

  # TODO: Tests marked as :redo_with_hot_observable? were converted from
  # corresponding RxJS 5 tests but changed to use a cold observable instead of
  # hot since we haven't implemented a testable HotObservable yet. Consider
  # redoing those tests when possible.

  describe "take/1" do
    test "should take two values from an observable with many values" do
      e1 = cold            "--a-----b----c---d--|"
      e1subs = sub_marbles "^       !            "
      expected = marbles   "--a-----(b|)         "

      assert observe(e1 |> take(2)) == expected
      assert subscriptions(e1) == e1subs
    end

    test "should work with empty" do
      e1 = cold            "|"
      e1subs = sub_marbles "(^!)"
      expected = marbles   "|"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    test "should go on forever on never" do
      e1 = cold            "-"
      e1subs = sub_marbles "^"
      expected = marbles   "-"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should be empty on take(0)" do
      e1 = cold            "--a--b---c---d--|"
      e1subs = {nil, nil}  # don't subscribe at all
      expected = marbles   "|"

      assert observe(e1 |> take(0)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should take one value of an observable with one value" do
      e1 = cold            "---(a|)"
      e1subs = sub_marbles "^  !   "
      expected = marbles   "---(a|)"

      assert observe(e1 |> take(1)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should take one value of an observable with many values" do
      e1 = cold            "---b----c---d--|"
      e1subs = sub_marbles "^  !            "
      expected = marbles   "---(b|)"

      assert observe(e1 |> take(1)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should wait to be done until delayed empty is done" do
      e1 = cold            "----|"
      e1subs = sub_marbles "^   !"
      expected = marbles   "----|"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should propagate error from the source observable" do
      e1 = cold            "----#", error: "too bad"
      e1subs = sub_marbles "^   !"
      expected = marbles   "----#", error: "too bad"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    @tag :redo_with_hot_observable?
    test "should propagate error from an observable with values" do
      e1 = cold            "---a--b--#"
      e1subs = sub_marbles "^        !"
      expected = marbles   "---a--b--#"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    # TODO: Can't do explicit unsubscribe in MarbleTesting yet.
    # it('should allow unsubscribing explicitly and early', () => {
    #   const e1 = hot('---^--a--b-----c--d--e--|');
    #   const unsub =     '         !            ';
    #   const e1subs =    '^        !            ';
    #   const expected =  '---a--b---            ';
    #
    #   expectObservable(e1.take(42), unsub).toBe(expected);
    #   expectSubscriptions(e1.subscriptions).toBe(e1subs);
    # });

    test "should work with throw" do
      e1 = cold            "#"
      e1subs = sub_marbles "(^!)"
      expected = marbles   "#"

      assert observe(e1 |> take(42)) == expected
      assert subscriptions(e1) == e1subs
    end

    test "should throw if count is less than zero" do
      assert_raise FunctionClauseError,
        fn -> Rx.Observable.range(0, 10) |> take(-1) end
    end

    test "should throw if count is not an integer" do
      assert_raise FunctionClauseError,
        fn -> Rx.Observable.range(0, 10) |> take(1.7) end
    end

    # TODO: Implement this when mergeMap is available.
    # it('should not break unsubscription chain when unsubscribed explicitly', () => {
    #   const e1 = hot('---^--a--b-----c--d--e--|');
    #   const unsub =     '         !            ';
    #   const e1subs =    '^        !            ';
    #   const expected =  '---a--b---            ';
    #
    #   const result = e1
    #     .mergeMap((x: string) => Observable.of(x))
    #     .take(42)
    #     .mergeMap((x: string) => Observable.of(x));
    #
    #   expectObservable(result, unsub).toBe(expected);
    #   expectSubscriptions(e1.subscriptions).toBe(e1subs);
    # });
  end
end
