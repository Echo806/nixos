{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/config".text = ''
    font-family = Maple Mono Custom
    font-family-bold = Maple Mono Custom
    font-family-italic = Maple Mono Custom
    font-family-bold-italic = Maple Mono Custom
    font-size = 12
    gtk-single-instance = false
  '';
}
