defmodule StopStage do
  @moduledoc false  # internal

  use GenStage

  defstruct reason: nil

  def start(%__MODULE__{reason: reason}, :producer, options \\ []), do:
    GenStage.start(__MODULE__, {reason || :normal, :producer}, options)

  def init({reason, :producer}), do:
    {:stop, reason}
end
