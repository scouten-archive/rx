defmodule OLD.Rx.Observable.ToNotificationsStage do
  @moduledoc false  # internal, implements Rx.Observable.to_notifications

  use OLD.Rx.Internal.TransformStage
  alias OLD.Rx.Internal.TransformStage

  defstruct placeholder: nil

  def start(%__MODULE__{}, type, options \\ []), do:
    TransformStage.start(__MODULE__, type, options)

  def init(_args), do:
    {:ok, [], :no_state}

  def handle_events(events, state), do:
    {:events, Enum.map(events, &({:next, &1})), state}

  def handle_done(state), do:
    {:done, [:done], state}

  def handle_error(error, state), do:
    {:done, [{:error, error}], state}
end
