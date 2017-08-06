defmodule CrashStage do
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
