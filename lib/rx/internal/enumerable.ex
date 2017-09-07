defmodule Rx.Internal.Enumerable.Observer do
  @moduledoc false

  import Rx.Internal.ValidObservable

  use Rx.Schedulable

  defstruct [:observable]

  def init(%__MODULE__{observable: source} = _), do:
    {:ok, [], start: [{0, :observable_source, enforce(source)}]}

  def handle_task({:next, values}, acc), do:
    {:ok, Enum.reverse(values) ++ acc}

  def handle_task({:error, error}, _acc), do:
    raise Rx.Error, error

  def handle_task(:done, acc), do:
    {:ok, acc, stop: [{:observable_source, :done}]}

  def terminate(_reason, acc), do: Enum.reverse(acc)
end

defmodule Rx.Internal.Enumerable do
  @moduledoc false

  import Rx.Internal.ValidObservable

  alias VirtualTimeScheduler, as: VTS
    # TODO: Replace VTS with a scheduler that's not designed for testing.

  def reduce(observable, acc, fun) do
    # TODO: Replace with streaming implementation.
    list = VTS.run(%Rx.Internal.Enumerable.Observer{observable: enforce(observable)})
    Enumerable.reduce(list, acc, fun)
  end
end
