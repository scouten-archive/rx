defmodule Rx.Observable.ToNotificationsStage do
  @moduledoc false  # internal, implements Rx.Obsevable.to_notifications

  use GenStage

  defstruct placeholder: nil

  def start(%__MODULE__{}, type, options \\ []) do
    GenStage.start(__MODULE__, type, options)
  end

  def init(type) do
    {type, :no_state}
  end

  def handle_subscribe(_type, _options, subscriber, _state) do
    {:automatic, subscriber}
  end

  def handle_events(events, _from, state) do
    {:noreply, Enum.map(events, &({:next, &1})), state}
  end

  def handle_cancel({:cancel, _reason}, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cancel({:down, :normal}, _from, state) do
    send(self(), :send_stop)
    {:noreply, [:done], state}
  end

  def handle_cancel({:down, {:shutdown, reason}}, _from, {pid, refs} = subscriber) do
    Process.send(pid, {:"$gen_consumer", {self(), refs}, [{:error, reason}]},
                 [:noconnect])
    {:stop, :normal, subscriber}
  end

  def handle_cancel({:down, reason}, _from, {pid, refs} = subscriber) do
    Process.send(pid, {:"$gen_consumer", {self(), refs}, [{:error, reason}]},
                 [:noconnect])
    {:stop, :normal, subscriber}
  end

  def handle_info(:send_stop, state) do
    {:stop, :normal, state}
  end

  def handle_info({:stop, _reason}, state) do
    {:stop, :normal, state}
      # Intentionally converting upstream error to :normal stop here.
  end
end
