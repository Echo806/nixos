{ config, pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans CJK SC" "WenQuanYi Micro Hei" "Noto Sans" ];
  };

  home.packages = with pkgs; [
    noto-fonts-cjk-sans
    wqy_microhei
  ];
}
