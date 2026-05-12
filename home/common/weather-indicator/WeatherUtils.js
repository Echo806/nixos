.pragma library

function formatTemp(temp, useFahrenheit, showUnit, LocationService) {
    const v = Math.round(useFahrenheit ? LocationService.celsiusToFahrenheit(temp) : temp);
    return v + (showUnit ? (useFahrenheit ? "°F" : "°C") : "");
}

function getTooltipRows(weather, tooltipOption, useFahrenheit, use12h, tr, LocationService, I18n) {
    if (!weather) return [];
    const rows = [];
    const fmt = use12h ? "hh:mm AP" : "HH:mm";

    const f = (t) => formatTemp(t, useFahrenheit, true, LocationService);

    if (tooltipOption === "everything") {
        rows.push([tr("tooltips.current"), f(weather.current_weather.temperature)]);
    }
    if (tooltipOption === "everything" || tooltipOption === "highlow") {
        // Show next few hours temperature range instead of daily high/low
        if (weather.hourly && weather.hourly.temperature_2m && weather.hourly.temperature_2m.length >= 6) {
            const temps = weather.hourly.temperature_2m.slice(0, 6);
            const hi = Math.max(...temps);
            const lo = Math.min(...temps);
            rows.push([tr("tooltips.high"), f(hi)]);
            rows.push([tr("tooltips.low"), f(lo)]);
        }
    }
    if (tooltipOption === "everything" || tooltipOption === "sunrise") {
        rows.push([tr("tooltips.sunrise"), I18n.locale.toString(new Date(weather.daily.sunrise[0]), fmt)]);
        rows.push([tr("tooltips.sunset"), I18n.locale.toString(new Date(weather.daily.sunset[0]), fmt)]);
    }
    return rows;
}
