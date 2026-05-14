{ config, pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Sarasa Gothic SC" "Noto Sans CJK SC" "WenQuanYi Micro Hei" "Noto Sans" ];
    serif = [
      "Sarasa Gothic SC"
    ];

    monospace = [
      "Sarasa Mono SC"
    ];
  };

  home.packages = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    wqy_microhei
  ];
}
