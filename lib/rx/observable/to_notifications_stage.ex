defmodule Rx.Observable.ToNotificationsStage do
  @moduledoc false  # internal, implements Rx.Obsevable.to_notifications

  use GenStage

  defstruct placeholder: nil

  def start(%__MODULE__{}, type, options \\ []), do:
    GenStage.start(__MODULE__, type, options)

  def init(type), do:
    {type, :not_yet_subscribed}

  def handle_subscribe(_type, _options, subscriber, _state), do:
    {:automatic, subscriber}

  def handle_events(events, _from, state), do:
    {:noreply, Enum.map(events, &({:next, &1})), state}

  def handle_cancel({:cancel, reason}, _from, state), do:
    send_termination(reason, state)
  def handle_cancel({:down, :normal}, _from, state), do:
    send_termination(:normal, state)
  def handle_cancel({:down, {:shutdown, reason}}, _from, state), do:
    send_termination(reason, state)
  def handle_cancel({:down, reason}, _from, state), do:
    send_termination(reason, state)

  def handle_info({:stop, _reason}, state), do:
    {:stop, :normal, state}
      # Intentionally converting upstream error to :normal stop here.

  defp send_termination(reason, {pid, refs} = subscriber) do
    Process.send(pid,
                 {:"$gen_consumer", {self(), refs}, [translate_reason(reason)]},
                 [:noconnect])
    {:stop, :normal, subscriber}
  end

  defp translate_reason(:normal), do: :done
  defp translate_reason(%Rx.Error{message: message}), do: {:error, message}
  defp translate_reason(reason), do: {:error, reason}
end
