{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    nerd-fonts.jetbrains-mono
    wps-symbol-fonts
  ];

  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
}
