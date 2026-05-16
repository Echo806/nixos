{ config, pkgs, lib, ... }:

{
  programs.noctalia-shell = {
    enable = true;
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

      desktopWidgets = {
        enabled = true;
        monitorWidgets = [
          {
            name = "eDP-1";
            widgets = [
              { id = "Clock"; x = 73; y = 17; scale = 1.0; }
              { id = "Weather"; x = 1250; y = 25; scale = 1.0; }
              { id = "MediaPlayer"; x = 578; y = 22; scale = 1.0; }
            ];
          }
        ];
      };

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
}
