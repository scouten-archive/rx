defmodule OLD.Rx.Observable.ThrowStage do
  @moduledoc false  # internal

  use GenStage

  defstruct message: nil

  def start(%__MODULE__{message: message}, :producer, options \\ []), do:
    GenStage.start(__MODULE__, {message, :producer}, options)

  def init({message, :producer}), do:
    {:producer, message}

  def handle_demand(_demand, message) do
    Process.send_after(self(), :send_stop, 10)
    {:noreply, [], message}
  end

  def handle_info(:send_stop, message), do:
    {:stop, {:shutdown, message}, message}
end
