{ pkgs }:

{
  system = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    nerd-fonts.jetbrains-mono
    wps-symbol-fonts
  ];

  home = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    wqy_microhei
  ];

  steam = with pkgs; [
    noto-fonts-cjk-sans
    wqy_microhei
  ];

  systemFontconfig = {
    sansSerif = [ "Sarasa Gothoc SC" "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "Sarasa Gothic SC" ];
    monospace = [ "Sarasa Mono SC" ];
  };

  homeFontconfig = {
    sansSerif = [ "Sarasa Gothic SC" "Noto Sans CJK SC" "WenQuanYi Micro Hei" "Noto Sans" ];
    serif = [ "Sarasa Gothic SC" ];
    monospace = [ "Sarasa Mono SC" ];
  };
}
