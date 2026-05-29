{ pkgs }:

{
  # Minimal office-document font set.  Keep Windows-compatible Chinese fonts for
  # documents authored on Windows/WPS/Office, plus Noto CJK as broad fallback.
  system = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    windows-fonts

    # Developer monospace font for terminals/editors. This custom package starts
    # from Maple Mono NL NF CN and bakes in the user's selected alternates from
    # https://font.subf.dev/zh-cn/playground/ so apps do not need runtime
    # font-feature support.
    maple-mono-custom
  ];

  steam = with pkgs; [
    noto-fonts-cjk-sans
  ];

  systemFontconfig = {
    sansSerif = [ "Microsoft YaHei" "Noto Sans CJK SC" "Noto Sans" ];
    serif = [ "SimSun" "Noto Serif CJK SC" "Noto Serif" ];
    monospace = [ "Maple Mono Custom" "Maple Mono NL NF CN" "Microsoft YaHei Mono" "Noto Sans Mono CJK SC" "Noto Sans Mono" ];
  };
}
