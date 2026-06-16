{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ../common/shell.nix
    ../common/git.nix
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
    ../apps/hermes.nix
    ../apps/libreoffice.nix
    ../apps/tailscale.nix
    ../apps/sunshine.nix
    ../apps/moonlight-qt.nix
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

  # ── runrun 专属: Hermes + 代理 (clash-verge) ──
  home.sessionVariables = {
    HERMES_HOME = "/home/run/.hermes";
    http_proxy = "http://127.0.0.1:7897";
    https_proxy = "http://127.0.0.1:7897";
    all_proxy = "socks5://127.0.0.1:7897";
    ALL_PROXY = "socks5://127.0.0.1:7897";
  };

  # ── x250 专属: HiDPI (4K 屏) ──
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  # Host-specific Noctalia desktop widget coordinates and language for runrun
  programs.noctalia-shell.settings = {
    general = {
      language = lib.mkForce "zh-CN";
    };

    # runrun 当前屏幕只有 1024x768 时，默认 single-row 大按钮会横向溢出，看起来不像铺满屏幕。
    # grid 在小分辨率下更稳；等 VGA-1 正常跑到 1920x1080 后仍然美观。
    sessionMenu = {
      largeButtonsLayout = "grid";
    };

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
