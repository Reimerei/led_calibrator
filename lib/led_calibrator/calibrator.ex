defmodule LedCalibrator.Calibrator do
  use GenServer
  require Logger

  alias LedCalibrator.{LedController, GammaCorrection}

  @first_color {128, 128, 128}
  @display_cal_endpoint "http://localhost:8080/ajax/messages"

  @red_correction 1.0
  @green_correction 0.66
  @blue_correction 0.95

  defmodule State do
    defstruct [:color]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %State{color: @first_color}

    send(self(), :next_color)
    {:ok, state}
  end

  def handle_info(:next_color, %State{} = state) do
    state.color
    # first gamma, then color corrections. We want to move the colors in the gama corrected space
    |> apply_corrections()
    |> LedController.set_color()

    state = get_next_color(state)

    send(self(), :next_color)

    {:noreply, state}
  end

  def get_next_color(%State{color: {r, g, b}} = state) do
    query = URI.encode("rgb(#{r}, #{g}, #{b}) 0.5")

    case Req.get("#{@display_cal_endpoint}?#{query}", receive_timeout: 120_000) do
      {:ok, %Req.Response{status: 200, body: "#" <> new_color}} ->
        color =
          hex_to_tuple(new_color)
          |> tap(fn c -> Logger.info("Got new color from DisplayCal: #{inspect(c)}") end)

        %State{state | color: color}

      {:error, reason} ->
        Logger.warning("DisplayCal request error: #{inspect(reason)}")
        state
    end
  end

  def apply_corrections({_r, _g, _b} = color) do
    color
    |> GammaCorrection.apply()
    |> then(fn {r, g, b} ->
      {round(r * @red_correction), round(g * @green_correction), round(b * @blue_correction)}
    end)
  end

  defp hex_to_tuple(<<r_str::binary-size(2), g_str::binary-size(2), b_str::binary-size(2)>>) do
    {r, ""} = Integer.parse(r_str, 16)
    {g, ""} = Integer.parse(g_str, 16)
    {b, ""} = Integer.parse(b_str, 16)
    {r, g, b}
  end
end
