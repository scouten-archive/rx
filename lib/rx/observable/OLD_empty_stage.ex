defmodule OLD.Rx.Observable.EmptyStage do
  @moduledoc false  # internal

  use GenStage

  defstruct placeholder: nil

  def start(%__MODULE__{}, :producer, options \\ []), do:
    GenStage.start(__MODULE__, :no_state, options)

  def init(:no_state), do:
    {:producer, :no_state}

  def handle_demand(_demand, message), do:
    {:stop, :normal, message}
end
