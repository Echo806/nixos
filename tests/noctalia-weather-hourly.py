#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SHELL_NIX = ROOT / "home/common/shell.nix"


def main() -> None:
    text = SHELL_NIX.read_text()

    checks = [
        (
            "Open-Meteo request includes hourly weather data",
            "hourly=temperature_2m,weathercode,precipitation_probability",
        ),
        (
            "WeatherCard exposes hourly forecast helper",
            "function hourlyForecastModel()",
        ),
        (
            "WeatherCard forecast uses hourly time labels",
            "LocationService.data.weather.hourly.time",
        ),
        (
            "WeatherCard forecast uses hourly weather icons",
            "icon: LocationService.weatherSymbolFromCode(modelData.weathercode)",
        ),
        (
            "WeatherCard forecast displays hourly temperature",
            'return modelData.temperature + "°";',
        ),
    ]

    failures = []
    for description, needle in checks:
        present = needle in text
        if not present:
            failures.append(description)

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}")
        raise SystemExit(1)

    print("PASS: Noctalia weather card is patched for hourly forecasts")


if __name__ == "__main__":
    main()
