{ pkgs }:

{
  system = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-han-sans
    source-han-serif
    wqy_microhei
    wqy_zenhei
    corefonts
    vista-fonts
    vista-fonts-chs
    local-windows-fonts
    ms-win10-fonts
    ms-win10-sc-sup-fonts
    wps-cjk-font-aliases
    lxgw-wenkai
    lxgw-fusionkai
    cns11643-kai
    nerd-fonts.jetbrains-mono
    wps-symbol-fonts
  ];

  home = with pkgs; [
    sarasa-gothic
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-han-sans
    source-han-serif
    wqy_microhei
    wqy_zenhei
    lxgw-wenkai
    lxgw-fusionkai
  ];

  steam = with pkgs; [
    noto-fonts-cjk-sans
    wqy_microhei
  ];

  systemFontconfig = {
    sansSerif = [ "Sarasa Gothic SC" "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "Noto Serif CJK SC" "Source Han Serif SC" "Noto Serif" ];
    monospace = [ "Sarasa Mono SC" ];
  };

  homeFontconfig = {
    sansSerif = [ "Sarasa Gothic SC" "Noto Sans CJK SC" "WenQuanYi Micro Hei" "Noto Sans" ];
    serif = [ "Noto Serif CJK SC" "Source Han Serif SC" "Noto Serif" ];
    monospace = [ "Sarasa Mono SC" ];
  };
}
