defmodule Rx.Internal.Enumerable.Observer do
  @moduledoc false

  import Rx.Internal.ValidObservable

  use Rx.Schedulable

  defstruct [:observable]

  @spec init(time :: number, args :: term) :: Rx.Schedulable.init_reply
  def init(_time, %__MODULE__{observable: source} = _), do:
    {:ok, [], start: [{0, :observable_source, enforce(source)}]}

  @spec handle_task(time :: number, args :: term, state :: term) ::
    Rx.Schedulable.handle_task_reply
  def handle_task(_time, {:next, values}, acc), do:
    {:ok, Enum.reverse(values) ++ acc}
  def handle_task(_time, {:error, error}, _acc), do:
    raise Rx.Error, error
  def handle_task(_time, :done, acc), do:
    {:ok, acc, stop: [{:observable_source, :done}]}

  @spec terminate(time :: number, reason :: Rx.Schedulable.reason, state :: term) :: any
  def terminate(_time, _reason, acc), do: Enum.reverse(acc)
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
