{ config, pkgs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
in
{
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = fonts.homeFontconfig;

  home.packages = fonts.home;
}
