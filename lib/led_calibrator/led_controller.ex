defmodule LedCalibrator.LedController do
  use GenServer
  require Logger

  @moduledoc """
  This module is responsible for connecting to the LED strip and setting the color.
  This where you need to put the custom code that connects to your project. In this example we are sending UDP packets.
  """

  @host ~c"localhost"
  @port 1337

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def set_color({r, g, b}) do
    Logger.debug("Setting color to [#{r}, #{g}, #{b}] ")
    GenServer.cast(__MODULE__, {:set_color, {r, g, b}})
  end

  def init(:ok) do
    {:ok, udp} = :gen_udp.open(0, active: false)

    {:ok, %{udp: udp}}
  end

  def handle_cast({:set_color, {r, g, b}}, %{udp: udp} = state) do
    binary = <<r::8, g::8, b::8>>
    :ok = :gen_udp.send(udp, @host, @port, binary)
    {:noreply, state}
  end
end
