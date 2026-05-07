{ config, pkgs, ... }:

{
  time.timeZone = "Asia/Hong_Kong";

  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;

    fcitx5.addons = with pkgs; [
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
    ];
  };

  environment.systemPackages = with pkgs; [
    rime-ice
  ];
}
