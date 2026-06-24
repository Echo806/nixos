#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SHELL_NIX = ROOT / "home/common/shell.nix"


def main() -> None:
    text = SHELL_NIX.read_text()

    checks = [
        (
            "LocationService refreshes cached weather without usable probability data",
            "precipitation_probability || []).every",
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
            "icon: LocationService.weatherSymbolFromCode(modelData.weathercode, modelData.isDay)",
        ),
        (
            "WeatherCard forecast carries hourly day/night state",
            '"isDay": isDays[i] ?? true',
        ),
        (
            "WeatherCard forecast displays hourly temperature",
            'return modelData.temperature + "°";',
        ),
        (
            "WeatherCard forecast carries hourly precipitation probability",
            '"precipitationProbability": precipitationProbabilities[i]',
        ),
        (
            "WeatherCard forecast displays precipitation probability",
            'return modelData.precipitationProbability + "%";',
        ),
        (
            "LocationService can read QWeather API host from the environment",
            'Quickshell.env("QWEATHER_API_HOST")',
        ),
        (
            "LocationService can authenticate QWeather API requests with a header",
            'xhr.setRequestHeader("X-QW-Api-Key", qweatherApiKey.trim());',
        ),
        (
            "LocationService fetches QWeather 24h hourly forecasts",
            'qweatherRequest("/v7/weather/24h"',
        ),
        (
            "LocationService transforms QWeather pop into precipitation probability",
            "hourlyPop.push(parseInt(hour.pop || 0));",
        ),
        (
            "LocationService preserves QWeather hourly day/night state",
            "hourlyIsDay.push(qweatherIsDay(hour.icon) ? 1 : 0);",
        ),
        (
            "LocationService stores hourly day/night state in the cache",
            '"is_day": hourlyIsDay',
        ),
        (
            "LocationService marks cached QWeather data with its source",
            '"source": "qweather"',
        ),
        (
            "LocationService requires QWeather credentials instead of falling back",
            "QWeather credentials missing",
        ),
        (
            "Noctalia service reads optional QWeather secret environment file",
            'EnvironmentFile = "-%h/.config/noctalia/qweather.env";',
        ),
        (
            "Noctalia weather location is configured for Panyu",
            'name = "Panyu,China";',
        ),
    ]

    failures = []
    for description, needle in checks:
        present = needle in text
        if not present:
            failures.append(description)

    if "api.open-meteo.com" in text or "models=cma_grapes_global" in text:
        failures.append("LocationService no longer uses Open-Meteo")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}")
        raise SystemExit(1)

    print("PASS: Noctalia weather card is patched for hourly forecasts")


if __name__ == "__main__":
    main()
