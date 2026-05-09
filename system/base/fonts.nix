{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    corefonts  # Webdings + Arial/Times/etc
    winePackages.fonts  # Symbol + Wingdings replacements
    vista-fonts
  ];

  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
}
