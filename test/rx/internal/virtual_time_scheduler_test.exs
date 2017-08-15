defmodule VirtualTimeSchedulerTest do
  use ExUnit.Case, async: true

  alias VirtualTimeScheduler, as: VTS

  test "can run a preconfigured sequence of events in order of addition" do
    v = VTS.new()
    my_ref = make_ref()

    invoke = fn(0, n) ->
      send(self(), {:invoked, my_ref, n})
    end

    v = VTS.schedule(v, 0, invoke, 1)
    v = VTS.schedule(v, 0, invoke, 2)
    v = VTS.schedule(v, 0, invoke, 3)
    v = VTS.schedule(v, 0, invoke, 4)
    v = VTS.schedule(v, 0, invoke, 5)
    VTS.run(v)

    assert_received {:invoked, ^my_ref, n}
    assert n == 1
    assert_received {:invoked, ^my_ref, n}
    assert n == 2
    assert_received {:invoked, ^my_ref, n}
    assert n == 3
    assert_received {:invoked, ^my_ref, n}
    assert n == 4
    assert_received {:invoked, ^my_ref, n}
    assert n == 5
    refute_received {:invoked, ^my_ref, _n}
  end

  test "can run tasks in order sorted by time, even if scheduled at random" do
    v = VTS.new()
    my_ref = make_ref()

    invoke = fn(time, n) ->
      send(self(), {:invoked, my_ref, time, n})
    end

    v = VTS.schedule(v, 0, invoke, 1)
    v = VTS.schedule(v, 100, invoke, 2)
    v = VTS.schedule(v, 0, invoke, 3)
    v = VTS.schedule(v, 500, invoke, 4)
    v = VTS.schedule(v, 0, invoke, 5)
    v = VTS.schedule(v, 100, invoke, 6)
    VTS.run(v)

    assert_received {:invoked, ^my_ref, time, n}
    assert time == 0
    assert n == 1
    assert_received {:invoked, ^my_ref, time, n}
    assert time == 0
    assert n == 3
    assert_received {:invoked, ^my_ref, time, n}
    assert time == 0
    assert n == 5
    assert_received {:invoked, ^my_ref, time, n}
    assert time == 100
    assert n == 2
    assert_received {:invoked, ^my_ref, time, n}
    assert time == 100
    assert n == 6
    assert_received {:invoked, ^my_ref, time, n}
    assert time == 500
    assert n == 4
    refute_received {:invoked, ^my_ref, _time, _n}
  end

  test "does not accept negative delays" do
    # NOTE: This differs from RxJS implementation. Maybe we'll have to revisit?

    v = VTS.new()
    assert_raise FunctionClauseError, fn ->
      VTS.schedule(v, -10, fn _time, _arg -> :noop end, 1)
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