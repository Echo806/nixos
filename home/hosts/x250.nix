{ config, pkgs, inputs, ... }:

{
  imports = [
    ../common/shell.nix
    ../common/git.nix
    ../apps/chrome.nix
    ../apps/qq.nix
    ../apps/wechat.nix
    ../apps/splayer.nix
    ../apps/clash-verge.nix
    ../apps/steam.nix
    ../apps/vscode.nix
    ../apps/codex.nix
    ../agent/memory/agentmemory.nix
    ../apps/ghostty.nix
    ../apps/neovim/default.nix
    ../apps/fastfetch.nix
    ../apps/claude-code.nix
    ../apps/hermes/default.nix
    ../apps/libreoffice.nix
    ../apps/tailscale.nix
    ../apps/sunshine.nix
    ../apps/moonlight-qt.nix
    ../apps/typora.nix
    ../apps/yazi.nix
    ../apps/localsend.nix
    ../apps/nautilus.nix
    ../apps/sshfs.nix
    ../apps/motrix-next.nix
    ../apps/wemeet.nix
  ];

  home.username = "run";
  home.homeDirectory = "/home/run";
  # ── 默认编辑器设为 neovim ──
  programs.neovim.defaultEditor = true;
  # ── 启用 bash 管理，让 HM 的 sessionVariables 能注入到 shell ──
  programs.bash.enable = true;

  # ── x250 专属: 代理 (clash-verge) ──
  home.sessionVariables = {
    HERMES_HOME = "/home/run/.hermes";
    http_proxy = "http://127.0.0.1:7897";
    https_proxy = "http://127.0.0.1:7897";
    all_proxy = "socks5://127.0.0.1:7897";
    ALL_PROXY = "socks5://127.0.0.1:7897";
    # Do not include IPv6 CIDR literals here: httpx parses them as host:port
    # patterns and raises "Invalid port: '115c:a1e0::'".
    no_proxy = "127.0.0.1,localhost,.tailnet.tomandjerry2026.xyz,desktop.tailnet.tomandjerry2026.xyz,100.64.0.0/10";
    NO_PROXY = "127.0.0.1,localhost,.tailnet.tomandjerry2026.xyz,desktop.tailnet.tomandjerry2026.xyz,100.64.0.0/10";
  };

  # ── x250 专属: HiDPI / cursor ──
  home.sessionVariables.XCURSOR_SIZE = "32";

  xresources.properties = {
    "Xcursor.size" = 32;
    "Xft.dpi" = 172;
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

/* Host-specific Noctalia widget coordinates for x250 (framework) */
/* Put precise coordinates here; left as zeros for later tuning. */
  programs.noctalia-shell.settings = {
    desktopWidgets = {
      enabled = true;
      monitorWidgets = [
        {
          name = "eDP-1";
          widgets = [
            { id = "Clock";       x = 73; y = 17; scale = 1.0; }
            { id = "Weather";     x = 1250; y = 25; scale = 1.0; }
            { id = "MediaPlayer"; x = 578; y = 22; scale = 1.0; }
          ];
        }
      ];
    };
  };
}

