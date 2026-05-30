{
  "mcp-nixos" = {
    command = "/run/current-system/sw/bin/nix";
    args = [ "run" "nixpkgs#mcp-nixos" ];
  };
}
