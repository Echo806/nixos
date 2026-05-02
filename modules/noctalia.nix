{ config, pkgs, ... }:

{
  programs.noctalia = {
    enable = true;
    defaultShell = pkgs.fish; # or zsh/bash if you prefer
  };

  programs.niri.enable = true;
}
