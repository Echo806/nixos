{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
}
