{ config, pkgs, inputs, lib, ... }:

let
  patched-noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Services/Location/LocationService.qml \
        --replace-fail \
        '&daily=temperature_2m_max,temperature_2m_min,weathercode,sunset,sunrise' \
        '&hourly=temperature_2m,weathercode,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,weathercode,sunset,sunrise'
    '';
  });
in {
  # 强制使用 patch 后的 noctalia-shell（覆盖 home-module 的默认值）
  programs.noctalia-shell.package = lib.mkForce patched-noctalia;

  # 部署修改后的天气插件文件（Nix store 只读链接，不可被 Noctalia 覆盖）
  xdg.configFile = {
    "noctalia/plugins/weather-indicator/WeatherCardExtra.qml" = {
      source = ./weather-indicator/WeatherCardExtra.qml;
      force = true;
    };
    "noctalia/plugins/weather-indicator/Panel.qml" = {
      source = ./weather-indicator/Panel.qml;
      force = true;
    };
    "noctalia/plugins/weather-indicator/WeatherUtils.js" = {
      source = ./weather-indicator/WeatherUtils.js;
      force = true;
    };
  };
}
