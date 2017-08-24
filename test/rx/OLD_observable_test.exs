defmodule OLD.Rx.ObservableTest.CrashStage do
  @moduledoc false  # internal

  use GenStage

  defstruct fun: nil

  def start(%__MODULE__{}, :producer, options \\ []) do
    GenStage.start(__MODULE__, {nil, :producer}, options)
  end

  def init({_nil, :producer}) do
    raise "test failure in init fn"
  end
end

defmodule OLD.Rx.ObservableTest do
  use ExUnit.Case, async: true

  doctest OLD.Rx.Observable

  import ExUnit.CaptureLog

  @empty_observable %OLD.Rx.Observable{} # not a supported use case!

  describe "add_stage/3 (internal)" do
    test "won't add stage to otherwise empty Observable" do
      assert_raise RuntimeError, fn ->
        OLD.Rx.Observable.to_notifications(@empty_observable)
      end
    end

    test "won't add stage to a non-Observable" do
      assert_raise RuntimeError, fn ->
        OLD.Rx.Observable.to_notifications("not an Observable")
      end
    end
  end

  @crash_observable %OLD.Rx.Observable{reversed_stages: [%__MODULE__.CrashStage{}]}

  describe "to_list/1 (via Enumerable)" do
    test "crashes if source stream crashes on construction" do
      capture_log(fn ->
        assert {{%RuntimeError{message: "test failure in init fn"}, _}, _} =
          catch_exit(Enum.to_list(@crash_observable))
      end)
    end
  end
end
