{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    nerd-fonts.jetbrains-mono
    wps-symbol-fonts
  ];

  fonts.fontconfig.defaultFonts=
  {
    sansSerif = [ "Sarasa Gothoc SC" "Noto Sans CJK SC" "Noto Sans" ];
    serif = ["Sarasa Gothic SC"];
    monospace = ["Sarasa Mono SC"];
  }; 
}
