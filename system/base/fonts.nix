{ config, pkgs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
in
{
  fonts.packages = fonts.system;
  fonts.fontconfig.defaultFonts = fonts.systemFontconfig;
}
