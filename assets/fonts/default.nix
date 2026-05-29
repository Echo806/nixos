{ pkgs }:

{
  # Minimal office-document font set.  Keep Windows-compatible Chinese fonts for
  # documents authored on Windows/WPS/Office, plus Noto CJK as broad fallback.
  system = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    corefonts
    vista-fonts
    vista-fonts-chs
    local-windows-fonts
    ms-win10-fonts
    ms-win10-sc-sup-fonts
  ];

  steam = with pkgs; [
    noto-fonts-cjk-sans
  ];

  systemFontconfig = {
    sansSerif = [ "Microsoft YaHei" "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "SimSun" "Noto Serif CJK SC" "Noto Serif" ];
    monospace = [ "Microsoft YaHei Mono" "Noto Sans Mono CJK SC" "Noto Sans Mono" ];
  };
}
