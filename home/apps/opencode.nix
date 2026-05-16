
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    opencode
  ];
  
  # Install the OPENCODE.md into the user's home so the opencode agent
  # can surface its usage guide (mirrors the claude-code setup).
  home.file."OPENCODE.md".source = ../../OPENCODE.md;
  # Ensure the opencode settings (MCP permission) are deployed to the user's
  # home so that opencode can access the nixos MCP in a reproducible way.
  home.file.".opencode/settings.local.json".source = ../../.opencode/settings.local.json;
}
