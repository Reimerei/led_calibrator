setup:
	mix deps.get

calibrate:
	iex -S mix

render_tables:
	mix run --no-start -e "LedCalibrator.Renderer.render_lookup"