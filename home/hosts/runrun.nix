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
    ../apps/neovim/default.nix
    ../apps/fastfetch.nix
    ../apps/claude-code.nix
    ../apps/onlyoffice-desktopeditors.nix
    ../apps/wpsoffice.nix
    ../apps/tailscale.nix
    ../apps/sunshine.nix
    ../apps/moonlight.nix
    ../apps/typora.nix
    ../apps/yazi.nix
    ../apps/localsend.nix
    ../apps/nautilus.nix
    ../apps/sshfs.nix
  ];

  home.username = "run";
  home.homeDirectory = "/home/run";
  # ── 默认编辑器设为 neovim ──
  programs.neovim.defaultEditor = true;
  programs.bash.enable = true;

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

  # Host-specific Noctalia desktop widget coordinates for runrun
  programs.noctalia-shell.settings = {
    desktopWidgets = {
      enabled = true;
      monitorWidgets = [
        {
          name = "VGA-1";
          widgets = [
            { id = "Clock";       x = 45; y = 17; scale = 1.0; }
            { id = "Weather";     x = 800; y = 25; scale = 0.8; }
            { id = "MediaPlayer"; x = 330; y = 22; scale = 1.0; }
          ];
        }
      ];
    };
  };

}
