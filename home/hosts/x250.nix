{ config, pkgs, inputs, ... }:

{
  imports = [
    ../common/shell.nix
    ../common/git.nix
    ../common/theme.nix
    ../common/fcitx5.nix
    ../apps/chrome.nix
    ../apps/qq.nix
    ../apps/wechat.nix
    ../apps/splayer.nix
    ../apps/clash-verge.nix
    ../apps/steam.nix
    ../apps/vscode.nix
    ../apps/codex.nix
    ../apps/ghostty.nix
    ../apps/neovim.nix
    ../apps/fastfetch.nix
    ../apps/claude-code.nix
    ../apps/onlyoffice-desktopeditors.nix
    ../apps/wpsoffice.nix
  ];

  home.username = "run";
  home.homeDirectory = "/home/run";
  # ── x250 专属: 代理 (clash-verge) ──
  home.sessionVariables = {
    http_proxy = "http://127.0.0.1:7897";
    https_proxy = "http://127.0.0.1:7897";
    all_proxy = "socks5:127.0.0.1:7897";
  };

  # ── x250 专属: HiDPI (4K 屏) ──
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
