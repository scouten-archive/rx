defmodule OLD.Rx.Observable.CreateStage do
  @moduledoc false  # internal

  use GenStage

  defstruct fun: nil

  def start(%__MODULE__{fun: fun}, :producer, options \\ [])
    when is_function(fun, 1)
  do
    GenStage.start(__MODULE__, {fun, :producer}, options)
  end

  def init({fun, :producer})
    when is_function(fun, 1)
  do
    {:producer, fun}
  end

  def handle_subscribe(:consumer, _options, from, fun)
    when is_function(fun, 1)
  do
    {:automatic, {fun, from}}
  end

  def handle_demand(_demand, {fun, {pid, subscription} = consumer})
    when is_function(fun, 1)
  do
    # From a GenStage perspective, this is all wrong, which is why
    # Rx.Observable.create should only be used for lightweight, mostly
    # demonstration purposes. This implementation completely ignores
    # demand and also inverts control. Also, it privately sends the
    # messages without using GenStage to do it.

    next = fn message ->
      Process.send(pid, {:"$gen_consumer", {self(), subscription}, [message]},
                   [:noconnect])
    end

    reason = try do
      fun.(next)
      :normal
    rescue
      err -> {:shutdown, err}
    end
    GenStage.async_info(self(), {:stop, reason})
    {:noreply, [], consumer}
  end

  def handle_info({:stop, reason}, state) do
    {:stop, reason, state}
  end
end
