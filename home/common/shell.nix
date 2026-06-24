{ config, pkgs, lib, inputs, ... }:

let
  noctaliaBase = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaShell = pkgs.runCommand "noctalia-shell-tray-names" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    cp -a ${noctaliaBase}/. $out/
    chmod u+w \
      $out/share/noctalia-shell/Modules/Bar/Widgets/Tray.qml \
      $out/share/noctalia-shell/Modules/Panels/Tray/TrayDrawerPanel.qml \
      $out/share/noctalia-shell/Modules/Bar/Extras/TrayMenu.qml \
      $out/share/noctalia-shell/Services/Location/LocationService.qml \
      $out/share/noctalia-shell/Modules/Cards/WeatherCard.qml

    python3 - <<'PY'
import os
from pathlib import Path

out = Path(os.environ["out"])
tray = out / "share/noctalia-shell/Modules/Bar/Widgets/Tray.qml"
drawer = out / "share/noctalia-shell/Modules/Panels/Tray/TrayDrawerPanel.qml"
menu = out / "share/noctalia-shell/Modules/Bar/Extras/TrayMenu.qml"
location = out / "share/noctalia-shell/Services/Location/LocationService.qml"
weather_card = out / "share/noctalia-shell/Modules/Cards/WeatherCard.qml"

func = """
  function trayDisplayName(item) {
    if (!item) return "Tray Item";

    function clean(value) {
      return (value || "").toString().trim();
    }

    function isBadMachineName(value) {
      const text = clean(value).toLowerCase();
      return !text
        || text === "tray-id"
        || text.includes("tray-icon")
        || text.includes("chrome_status_icon")
        || text.includes("chrome-status-icon");
    }

    // Prefer user-facing SNI fields first. Id/name are often internal DBus
    // identifiers such as chrome_status_icon_1 or tray-icon tray app main.
    const preferred = clean(item.tooltipTitle) || clean(item.title);
    if (preferred) return preferred;

    if (!isBadMachineName(item.name)) return clean(item.name);
    if (!isBadMachineName(item.id)) return clean(item.id);

    // Small fallback set for apps that do not publish any useful title/tooltip.
    const raw = [item.id || "", item.name || "", item.icon || ""].join(" ").toLowerCase();
    if (raw.includes("chrome_status_icon") || raw.includes("chrome-status-icon")) return "QQ";

    return "Tray Item";
  }
"""

def patch_once(path, old, new):
    text = path.read_text()
    if old not in text:
        raise SystemExit(f'missing pattern in {path}: {old!r}')
    path.write_text(text.replace(old, new, 1))

def replace_qml_function(path, signature, replacement):
    text = path.read_text()
    start = text.find(signature)
    if start < 0:
        raise SystemExit(f'missing function in {path}: {signature!r}')

    brace = text.find("{", start)
    if brace < 0:
        raise SystemExit(f'missing function body in {path}: {signature!r}')

    depth = 0
    end = None
    for i in range(brace, len(text)):
        char = text[i]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break

    if end is None:
        raise SystemExit(f'unterminated function in {path}: {signature!r}')

    path.write_text(text[:start] + replacement + text[end:])

patch_once(tray, '  function _performFilteredItemsUpdate() {', func + '\n  function _performFilteredItemsUpdate() {')
text = tray.read_text()
text = text.replace('const title = item.tooltipTitle || item.name || item.id || "";', 'const title = root.trayDisplayName(item);')
text = text.replace('const title2 = item2.tooltipTitle || item2.name || item2.id || "";', 'const title2 = root.trayDisplayName(item2);')
text = text.replace('TooltipService.show(tooltipAnchor, modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item", BarService.getTooltipDirection(root.screen?.name));', 'TooltipService.show(tooltipAnchor, root.trayDisplayName(modelData), BarService.getTooltipDirection(root.screen?.name));')
tray.write_text(text)

patch_once(drawer, '  // Auto-close drawer when all items are pinned (drawer becomes empty)', func + '\n  // Auto-close drawer when all items are pinned (drawer becomes empty)')
text = drawer.read_text()
text = text.replace('const title = item?.tooltipTitle || item?.name || item?.id || "";', 'const title = root.trayDisplayName(item);')
text = text.replace('TooltipService.show(trayIcon, modelData.tooltipTitle || modelData.name || modelData.id || "Tray Item", BarService.getTooltipDirection(root.screen?.name));', 'TooltipService.show(trayIcon, root.trayDisplayName(modelData), BarService.getTooltipDirection(root.screen?.name));')
drawer.write_text(text)

patch_once(menu, '  readonly property QsMenuHandle menu: isSubMenu ? null : (trayItem ? trayItem.menu : null)', '  readonly property QsMenuHandle menu: isSubMenu ? null : (trayItem ? trayItem.menu : null)\n' + func)
text = menu.read_text()
text = text.replace('const itemName = trayItem.tooltipTitle || trayItem.name || trayItem.id || "";', 'const itemName = root.trayDisplayName(trayItem);')
menu.write_text(text)

patch_once(
    location,
    'const needsWeatherUpdate = (adapter.weatherLastFetch === "") || (adapter.weather === null) || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency);',
    'const needsWeatherUpdate = (adapter.weatherLastFetch === "") || (adapter.weather === null) || !adapter.weather.hourly || !adapter.weather.hourly.precipitation_probability || (adapter.weather.hourly.precipitation_probability || []).every(value => value === null) || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency);',
)
qweather_helpers = """
  readonly property string qweatherApiHost: Quickshell.env("QWEATHER_API_HOST") || ""
  readonly property string qweatherApiKey: Quickshell.env("QWEATHER_API_KEY") || ""

  function qweatherEnabled() {
    return qweatherApiHost.trim() !== "" && qweatherApiKey.trim() !== "";
  }

  function qweatherIconToWmo(icon) {
    const code = parseInt(icon || 0);
    if (code === 100 || code === 150 || code === 900)
      return 0;
    if (code === 101 || code === 102 || code === 151 || code === 152)
      return 2;
    if (code === 103 || code === 153)
      return 1;
    if (code === 104 || code === 901)
      return 3;
    if (code === 300 || code === 301 || code === 350 || code === 351)
      return 80;
    if (code === 302 || code === 303)
      return 95;
    if (code === 304)
      return 96;
    if (code === 305 || code === 309)
      return 51;
    if (code === 306 || code === 314 || code === 399)
      return 61;
    if (code === 307 || code === 315)
      return 63;
    if ((code >= 308 && code <= 313) || (code >= 316 && code <= 318))
      return 65;
    if (code >= 400 && code <= 499)
      return code >= 402 && code <= 403 ? 75 : 71;
    if (code >= 500 && code <= 599)
      return 45;
    return 3;
  }

  function qweatherIsDay(icon) {
    const code = parseInt(icon || 100);
    return !((code >= 150 && code < 200) || code === 350 || code === 351 || code === 456 || code === 457);
  }

  function qweatherTimezoneOffset(hourly) {
    if (!hourly || hourly.length === 0 || !hourly[0].fxTime)
      return "";
    const match = hourly[0].fxTime.match(/([+-][0-9]{2}:[0-9]{2}|Z)$/);
    return match ? match[1] : "";
  }

  function qweatherDateTime(date, time, fallback, offset) {
    if (time && time.indexOf("T") >= 0)
      return time;
    return date + "T" + (time || fallback) + (offset || "");
  }

  function qweatherUrl(path, latitude, longitude) {
    const host = qweatherApiHost.trim().replace(/\\/+$/, "");
    return host + path + "?location=" + encodeURIComponent(longitude + "," + latitude);
  }

  function qweatherRequest(path, latitude, longitude, callback, errorCallback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            var response = JSON.parse(xhr.responseText);
            if (response.code === "200") {
              callback(response);
            } else {
              errorCallback("Location", `QWeather API error: ''${response.code} ''${xhr.responseText}`);
            }
          } catch (e) {
            errorCallback("Location", "Failed to parse QWeather data: " + e);
          }
        } else {
          errorCallback("Location", `QWeather HTTP error: ''${xhr.status} ''${xhr.responseText}`);
        }
      }
    };
    xhr.open("GET", qweatherUrl(path, latitude, longitude));
    xhr.setRequestHeader("X-QW-Api-Key", qweatherApiKey.trim());
    xhr.send();
  }

  function transformQWeather(latitude, longitude, nowData, hourlyData, dailyData) {
    const hourly = hourlyData.hourly || [];
    const daily = dailyData.daily || [];
    const now = nowData.now || {};
    const offset = qweatherTimezoneOffset(hourly);
    const nowIsDay = qweatherIsDay(now.icon);
    const hourlyTimes = [];
    const hourlyTemps = [];
    const hourlyCodes = [];
    const hourlyPop = [];
    const hourlyIsDay = [];

    for (let i = 0; i < hourly.length; i++) {
      const hour = hourly[i];
      hourlyTimes.push(hour.fxTime);
      hourlyTemps.push(parseFloat(hour.temp || 0));
      hourlyCodes.push(qweatherIconToWmo(hour.icon));
      hourlyPop.push(parseInt(hour.pop || 0));
      hourlyIsDay.push(qweatherIsDay(hour.icon) ? 1 : 0);
    }

    const dailyTimes = [];
    const dailyMax = [];
    const dailyMin = [];
    const dailyCodes = [];
    const sunrise = [];
    const sunset = [];
    for (let i = 0; i < daily.length; i++) {
      const day = daily[i];
      dailyTimes.push(day.fxDate);
      dailyMax.push(parseFloat(day.tempMax || 0));
      dailyMin.push(parseFloat(day.tempMin || 0));
      dailyCodes.push(qweatherIconToWmo(day.iconDay || day.iconNight));
      sunrise.push(qweatherDateTime(day.fxDate, day.sunrise, "06:00", offset));
      sunset.push(qweatherDateTime(day.fxDate, day.sunset, "18:00", offset));
    }

    return {
      "source": "qweather",
      "latitude": parseFloat(latitude),
      "longitude": parseFloat(longitude),
      "timezone_abbreviation": "QWeather",
      "current": {
        "relativehumidity_2m": parseInt(now.humidity || 0),
        "surface_pressure": parseFloat(now.pressure || 0),
        "is_day": nowIsDay ? 1 : 0
      },
      "current_weather": {
        "time": now.obsTime || (hourly.length > 0 ? hourly[0].fxTime : ""),
        "interval": 900,
        "temperature": parseFloat(now.temp || 0),
        "windspeed": parseFloat(now.windSpeed || 0),
        "winddirection": parseInt(now.wind360 || 0),
        "is_day": nowIsDay ? 1 : 0,
        "weathercode": qweatherIconToWmo(now.icon)
      },
      "hourly": {
        "time": hourlyTimes,
        "temperature_2m": hourlyTemps,
        "weathercode": hourlyCodes,
        "precipitation_probability": hourlyPop,
        "is_day": hourlyIsDay
      },
      "hourly_units": {
        "precipitation_probability": "%"
      },
      "daily": {
        "time": dailyTimes,
        "temperature_2m_max": dailyMax,
        "temperature_2m_min": dailyMin,
        "weathercode": dailyCodes,
        "sunrise": sunrise,
        "sunset": sunset
      }
    };
  }

  function fetchQWeatherData(latitude, longitude, errorCallback) {
    Logger.d("Location", "Fetching weather from QWeather");
    var nowData = null;
    var hourlyData = null;
    var dailyData = null;
    var pending = 3;
    var failed = false;

    function done() {
      pending -= 1;
      if (failed || pending > 0)
        return;

      var weatherData = transformQWeather(latitude, longitude, nowData, hourlyData, dailyData);
      data.weather = weatherData;
      data.weatherLastFetch = Time.timestamp;
      root.stableLatitude = data.latitude = weatherData.latitude.toString();
      root.stableLongitude = data.longitude = weatherData.longitude.toString();
      root.coordinatesReady = true;
      isFetchingWeather = false;
      Logger.d("Location", "Cached QWeather data to disk - stable coordinates updated");
    }

    function fail(module, message) {
      if (failed)
        return;
      failed = true;
      errorCallback(module, message);
    }

    qweatherRequest("/v7/weather/now", latitude, longitude, function (response) {
      nowData = response;
      done();
    }, fail);
    qweatherRequest("/v7/weather/24h", latitude, longitude, function (response) {
      hourlyData = response;
      done();
    }, fail);
    qweatherRequest("/v7/weather/7d", latitude, longitude, function (response) {
      dailyData = response;
      done();
    }, fail);
  }

"""

patch_once(
    location,
    '  // Fetch weather data if enabled and coordinates are available',
    qweather_helpers + '  // Fetch weather data if enabled and coordinates are available',
)
patch_once(
    location,
    'const needsWeatherUpdate = (adapter.weatherLastFetch === "") || (adapter.weather === null) || !adapter.weather.hourly || !adapter.weather.hourly.precipitation_probability || (adapter.weather.hourly.precipitation_probability || []).every(value => value === null) || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency);',
    'const needsWeatherUpdate = (adapter.weatherLastFetch === "") || (adapter.weather === null) || (qweatherEnabled() && adapter.weather.source !== "qweather") || !adapter.weather.hourly || !adapter.weather.hourly.is_day || !adapter.weather.hourly.precipitation_probability || (adapter.weather.hourly.precipitation_probability || []).every(value => value === null) || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency);',
)
patch_once(
    location,
    'fetchWeatherData(adapter.latitude, adapter.longitude, errorCallback);',
    'if (!qweatherEnabled()) {\n        errorCallback("Location", "QWeather credentials missing");\n        return;\n      }\n      fetchQWeatherData(adapter.latitude, adapter.longitude, errorCallback);',
)
replace_qml_function(
    location,
    '  function fetchWeatherData(latitude, longitude, errorCallback) {',
    "  // Disabled: this build uses QWeather as the only weather provider.\n"
    "  function fetchWeatherData(latitude, longitude, errorCallback) {\n"
    "    errorCallback(\"Location\", \"Legacy weather provider is disabled\");\n"
    "  }",
)

text = location.read_text()
text = text.replace(
    '  function weatherSymbolFromCode(code) {\n    var isDay = data.weather ? data.weather.current_weather.is_day : true;',
    '  function weatherSymbolFromCode(code, isDayOverride) {\n    var rawIsDay = isDayOverride !== undefined ? isDayOverride : (data.weather ? data.weather.current_weather.is_day : true);\n    var isDay = rawIsDay === true || rawIsDay === 1;',
)
text = text.replace(
    '  function taliaWeatherImageFromCode(code) {\n    var isDay = data.weather ? data.weather.current_weather.is_day : true;',
    '  function taliaWeatherImageFromCode(code, isDayOverride) {\n    var rawIsDay = isDayOverride !== undefined ? isDayOverride : (data.weather ? data.weather.current_weather.is_day : true);\n    var isDay = rawIsDay === true || rawIsDay === 1;',
)
location.write_text(text)

hourly_helpers = """
  property int forecastStepHours: 2

  function hourlyForecastModel() {
    if (!weatherReady || !LocationService.data.weather.hourly || !LocationService.data.weather.hourly.time)
      return [];

    const hourly = LocationService.data.weather.hourly;
    const times = hourly.time || [];
    const codes = hourly.weathercode || [];
    const temps = hourly.temperature_2m || [];
    const precipitationProbabilities = hourly.precipitation_probability || [];
    const isDays = hourly.is_day || [];
    const now = Date.now();
    let start = 0;

    for (let i = 0; i < times.length; i++) {
      const t = Date.parse(times[i]);
      if (!isNaN(t) && t >= now) {
        start = i;
        break;
      }
    }

    const result = [];
    for (let i = start; i < times.length && result.length < root.forecastDays; i += root.forecastStepHours) {
      let temp = temps[i] ?? 0;
      if (Settings.data.location.useFahrenheit)
        temp = LocationService.celsiusToFahrenheit(temp);

      result.push({
        "time": times[i],
        "weathercode": codes[i] ?? 0,
        "isDay": isDays[i] ?? true,
        "temperature": Math.round(temp),
        "precipitationProbability": precipitationProbabilities[i] ?? null
      });
    }
    return result;
  }
"""

patch_once(
    weather_card,
    '  // Weather condition detection',
    hourly_helpers + '\n  // Weather condition detection',
)
text = weather_card.read_text()
text = text.replace(
    'model: weatherReady ? Math.min(root.forecastDays, LocationService.data.weather.daily.time.length) : 0',
    'model: root.hourlyForecastModel()',
)
text = text.replace(
    """              var weatherDate = new Date(LocationService.data.weather.daily.time[index].replace(/-/g, "/"));
              return I18n.locale.toString(weatherDate, "ddd");""",
    """              var weatherDate = new Date(modelData.time);
              return I18n.locale.toString(weatherDate, Settings.data.location.use12hourFormat ? "h AP" : "HH:mm");""",
)
text = text.replace(
    'icon: LocationService.weatherSymbolFromCode(LocationService.data.weather.daily.weathercode[index])',
    'icon: LocationService.weatherSymbolFromCode(modelData.weathercode, modelData.isDay)',
)
text = text.replace(
    'source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(LocationService.data.weather.daily.weathercode[index]))',
    'source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(modelData.weathercode, modelData.isDay))',
)
text = text.replace(
    """              var max = LocationService.data.weather.daily.temperature_2m_max[index];
              var min = LocationService.data.weather.daily.temperature_2m_min[index];
              if (Settings.data.location.useFahrenheit) {
                max = LocationService.celsiusToFahrenheit(max);
                min = LocationService.celsiusToFahrenheit(min);
              }
              max = Math.round(max);
              min = Math.round(min);
              return `''${max}°/''${min}°`;""",
    """              return modelData.temperature + "°";""",
)
text = text.replace(
    """          NText {
            Layout.alignment: Qt.AlignHCenter
            text: {
              return modelData.temperature + "°";
            }
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }""",
    """          NText {
            Layout.alignment: Qt.AlignHCenter
            text: {
              return modelData.temperature + "°";
            }
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
          }
          NText {
            Layout.alignment: Qt.AlignHCenter
            visible: modelData.precipitationProbability !== null
            text: {
              return modelData.precipitationProbability + "%";
            }
            pointSize: Style.fontSizeXS
            color: Color.mPrimary
          }""",
    1,
)
weather_card.write_text(text)
PY

    # The upstream noctalia-shell executable is a binary wrapper that embeds
    # QS_CONFIG_PATH pointing at the original store path. Since we copied and
    # patched the QML into $out, force QS_CONFIG_PATH before delegating to the
    # original wrapper; its --set-default then keeps our patched path.
    chmod u+w $out/bin $out/bin/noctalia-shell
    mv $out/bin/noctalia-shell $out/bin/.noctalia-shell-orig
    cat > $out/bin/noctalia-shell <<EOF
#!/bin/sh
export QS_CONFIG_PATH="$out/share/noctalia-shell"
exec "$out/bin/.noctalia-shell-orig" "\$@"
EOF
    chmod +x $out/bin/noctalia-shell
  '';
in
{
  programs.noctalia-shell = {
    enable = true;
    package = noctaliaShell;
    settings = {
      bar = {
        density = "comfortable";
        position = "left";
        widgets = {
          left = [
            { id = "Launcher"; }
            {
              formatVertical = "ddd  - MMM dd - HH mm";
              id = "Clock";
            }
          ];
          center = [
            { id = "Workspace"; labelMode = "none"; hideUnoccupied = false; }
          ];
          right = [
            { id = "Tray"; }
            { id = "Battery"; warningThreshold = 30; alwaysShowPercentage = false; }
            { id = "Volume"; }
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
          ];
        };
      };
      general = {
        avatarImage = "/home/run/nixos/assets/avator/妖夢.jpg";
        language = "en";
      };
      location = {
        monthBeforeDay = true;
        name = "Panyu,China";
      };

      desktopWidgets = {};

      wallpaper = {
        enabled = true;
        directory = "/home/run/nixos/assets/wallpapers";
        viewMode = "recursive";
      };
    }; 

    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        catwalk = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };

    pluginSettings = {
      catwalk = {
        minimumThreshold = 25;
        hideBackground = true;
      };
    };
  };

  # ── 强制覆盖现有 settings.json（noctalia 模块创建符号链接，但我们需要可写文件） ──
  xdg.configFile."noctalia/settings.json".force = true;

  # ── 使 settings.json 可写（Noctalia 需要在运行时保存 widget 位置） ──
  home.activation.makeNoctaliaSettingsWritable = lib.hm.dag.entryAfter ["writeBoundary"] ''
    s="${config.home.homeDirectory}/.config/noctalia/settings.json"
    if [ -h "$s" ]; then
      store="$(${pkgs.coreutils}/bin/readlink -f "$s")"
      ${pkgs.coreutils}/bin/rm "$s"
      ${pkgs.coreutils}/bin/cp --no-preserve=mode "$store" "$s"
    fi
  '';

  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "Noctalia Shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      EnvironmentFile = "-%h/.config/noctalia/qweather.env";
      ExecStart = "${noctaliaShell}/bin/noctalia-shell";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
