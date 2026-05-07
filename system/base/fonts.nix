{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
}
