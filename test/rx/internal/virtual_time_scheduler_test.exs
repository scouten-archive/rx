defmodule VirtualTimeSchedulerTest do
  use ExUnit.Case, async: true

  alias VirtualTimeScheduler, as: VTS

  test "can run a preconfigured sequence of events in order of addition" do
    v = VTS.new([])

    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    v = VTS.schedule(v, 0, invoke, 1)
    v = VTS.schedule(v, 0, invoke, 2)
    v = VTS.schedule(v, 0, invoke, 3)
    v = VTS.schedule(v, 0, invoke, 4)
    v = VTS.schedule(v, 0, invoke, 5)

    res = v
      |> VTS.run()
      |> Enum.reverse()

    assert res == [{0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}]
  end

  test "can run tasks in order sorted by time, even if scheduled at random" do
    v = VTS.new([])

    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    v = VTS.schedule(v, 0, invoke, 1)
    v = VTS.schedule(v, 100, invoke, 2)
    v = VTS.schedule(v, 0, invoke, 3)
    v = VTS.schedule(v, 500, invoke, 4)
    v = VTS.schedule(v, 0, invoke, 5)
    v = VTS.schedule(v, 100, invoke, 6)

    res = v
      |> VTS.run()
      |> Enum.reverse()

    assert res == [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  test "can run tasks that call different functions" do
    v = VTS.new([])

    invoke = fn(time, n, acc) ->
      {[{time, n} | acc], []}
    end

    reverse = fn(_time, :ignore, acc) ->
      {Enum.reverse(acc), []}
    end

    v = VTS.schedule(v, 0, invoke, 1)
    v = VTS.schedule(v, 100, invoke, 2)
    v = VTS.schedule(v, 0, invoke, 3)
    v = VTS.schedule(v, 500, invoke, 4)
    v = VTS.schedule(v, 0, invoke, 5)
    v = VTS.schedule(v, 100, invoke, 6)
    v = VTS.schedule(v, 700, reverse, :ignore)

    res = VTS.run(v)

    assert res == [{0, 1}, {0, 3}, {0, 5}, {100, 2}, {100, 6}, {500, 4}]
  end

  test "does not accept negative delays" do
    # NOTE: This differs from RxJS implementation. Maybe we'll have to revisit?

    v = VTS.new(:nop)
    assert_raise FunctionClauseError, fn ->
      VTS.schedule(v, -10, fn _time, _arg, _acc -> :noop end, 1)
    end
  end

  #   it('should support recursive scheduling', () => {
  #     const v = new VirtualTimeScheduler();
  #     let count = 0;
  #     const expected = [100, 200, 300];
  #
  #     v.schedule<string>(function(this: VirtualAction<string>, state: string) {
  #       if (++count === 3) {
  #         return;
  #       }
  #       expect(this.delay).to.equal(expected.shift());
  #       this.schedule(state, this.delay);
  #     }, 100, 'test');
  #
  #     v.run();
  #     expect(count).to.equal(3);
  #   });
  #
  #   it('should not execute virtual actions that have been rescheduled before run', () => {
  #     const v = new VirtualTimeScheduler();
  #     let messages = [];
  #     let action: VirtualAction<string> = <VirtualAction<string>> v.schedule(function(state: string) {
  #       messages.push(state);
  #     }, 10, 'first message');
  #     action = <VirtualAction<string>> action.schedule('second message' , 10);
  #     v.run();
  #     expect(messages).to.deep.equal(['second message']);
  #   });
  # });
end
