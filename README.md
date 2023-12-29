# Led Calibrator

Create color calbirations for your leds!

## Coloriemeters

Should work with everything supported by DisplayCal. Tested with:

* Spyder 3
* Spyder 4


## Dependencies

* elixir
* DisplayCal


## Steps

1. Start DisplayCal and choose `Web @ localhost` as Display
2. Run `make setup` to fetch dependencies.
3. Adjust `LedCalibrator.LedController` so it connects to your specific setup. It needs to set the given RGB values on the LEDs that are measured with your device. The current setup send UDP packets with the colors to localhost:1337.
4. Run `make calibrate`. It will connect to DisplayCal and render the required colors. (Don't worry about the errors, they should dissappear once the calibration is started)
5. In DisplayCal make sure "Interactive Display Adjustment" is enabled (Calibration Tab)
  * Use the gamma 2.2 Curve, it has shown the best results.
  * Other settings on "As Measured"
  * Very high calibration speed is good enough
6. Start the calibration in DisplayCal
4. Start the initial adjustments with "Start measurement"
  * Adjust the red/green/blue correction ratios in `LedCalibrator.Calibrator` until the colors are at the right levels
  * The color levels are much more important than the right brightness.
5. Go on "stop measurement" and "Continue to Calibration"
  * This will take 30-60 min
6. Copy the resulting .cal file into this directory (mac: ~Library/Application\ Support/DisplayCAL/storage/)
7. Render the calibration tables with `make render_tables`. You can adjust `LedCalibrator.Renderer` if you need different syntax