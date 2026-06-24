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
    'const needsWeatherUpdate = (adapter.weatherLastFetch === "") || (adapter.weather === null) || !adapter.weather.hourly || (Time.timestamp >= adapter.weatherLastFetch + weatherUpdateFrequency);',
)
patch_once(
    location,
    'var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true&current=relativehumidity_2m,surface_pressure,is_day&daily=temperature_2m_max,temperature_2m_min,weathercode,sunset,sunrise&timezone=auto";',
    'var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&models=cma_grapes_global&current_weather=true&current=relativehumidity_2m,surface_pressure,is_day&hourly=temperature_2m,weathercode,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,weathercode,sunset,sunrise&timezone=auto";',
)

hourly_helpers = """
  property int forecastStepHours: 2

  function hourlyForecastModel() {
    if (!weatherReady || !LocationService.data.weather.hourly || !LocationService.data.weather.hourly.time)
      return [];

    const hourly = LocationService.data.weather.hourly;
    const times = hourly.time || [];
    const codes = hourly.weathercode || [];
    const temps = hourly.temperature_2m || [];
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
        "temperature": Math.round(temp)
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
    'icon: LocationService.weatherSymbolFromCode(modelData.weathercode)',
)
text = text.replace(
    'source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(LocationService.data.weather.daily.weathercode[index]))',
    'source: Qt.resolvedUrl(LocationService.taliaWeatherImageFromCode(modelData.weathercode))',
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
        name = "Guangzhou,China";
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
      ExecStart = "${noctaliaShell}/bin/noctalia-shell";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
