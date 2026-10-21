# FIT Converter

Convert workout FIT files to reference JSON, retaining GPS, distance and steps while removing health telemetry and device identifiers.

Use this when a watch recorded the same walk as the app and you want to compare the two in the Visualizer. The pipeline has been used with Garmin workouts exported through Gadgetbridge. By default it preserves recorded GPS points, including outliers and pauses, for later analysis.

Run from the repository root with `uv`; dependencies are declared in the script and installed automatically:

```sh
uv run tools/fit_converter/convert_fit.py workout.fit -o reference.json
```

Without `-o`, output is written beside the input using the `.json` extension. Filtering and timer-based trimming are optional. GPS coordinates remain sensitive even after health telemetry is removed: inspect the output before committing it and keep raw FIT files out of Git.

[Setup, options and data handling](../../wiki/Data-and-Tools.md#fit-converter).
