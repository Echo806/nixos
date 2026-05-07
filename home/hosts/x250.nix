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
  ];

  home.username = "run";
  home.homeDirectory = "/home/run";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
