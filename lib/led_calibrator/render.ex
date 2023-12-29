defmodule LedCalibrator.Renderer do
  alias LedCalibrator.Calibrator

  @moduledoc """
  Renders the lookup table with the color calibration.

  This will need to be customized for each projects
  """

  @filename "calibration_tables.h"

  def render_lookup() do
    values =
      find_file()
      |> tap(fn _ -> IO.puts("Parsing file...") end)
      |> File.stream!()
      |> Stream.drop_while(&(&1 != "BEGIN_DATA\n"))
      |> Stream.drop(1)
      |> Stream.take_while(&(&1 != "END_DATA\n"))
      |> Stream.map(&String.trim(&1))
      |> Enum.map(fn row ->
        String.split(row, " ")
        |> Enum.map(fn bin -> String.to_float(bin) end)
        |> Enum.map(&round(&1 * 255))
      end)

    reds = Enum.map(values, fn [_, r, _, _] -> r end)
    greens = Enum.map(values, fn [_, _, g, _] -> g end)
    blues = Enum.map(values, fn [_, _, _, b] -> b end)

    reds_with_correction =
      0..255
      |> Enum.map(fn r ->
        {r, _, _} = Calibrator.apply_corrections({r, 0, 0})
        Enum.at(reds, r)
      end)

    greens_with_corrections =
      0..255
      |> Enum.map(fn g ->
        {_, g, _} = Calibrator.apply_corrections({0, g, 0})
        Enum.at(greens, g)
      end)

    blues_with_corrections =
      0..255
      |> Enum.map(fn b ->
        {_, _, b} = Calibrator.apply_corrections({0, 0, b})
        Enum.at(blues, b)
      end)

    IO.puts("Rendering lookup table to #{@filename}")

    file = File.open!(@filename, [:write])

    IO.write(
      file,
      "const uint8_t calibration_red[256] = { #{Enum.join(reds_with_correction, ", ")} };\n"
    )

    IO.write(
      file,
      "const uint8_t calibration_green[256] = { #{Enum.join(greens_with_corrections, ", ")} };\n"
    )

    IO.write(
      file,
      "const uint8_t calibration_blue[256] = { #{Enum.join(blues_with_corrections, ", ")} };\n"
    )

    File.close(file)
  end

  def find_file() do
    cal_files =
      File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".cal"))
      |> Enum.sort_by(fn file ->
        {:ok, %File.Stat{mtime: mtime}} = File.stat(file)
        mtime
      end)

    last_modified = List.last(cal_files)

    IO.puts("""
    Found #{length(cal_files)} .cal files.
    Using the one last modified: #{inspect(last_modified)}
    """)

    last_modified
  end
end
