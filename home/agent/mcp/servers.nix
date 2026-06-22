{
  "mcp-nixos" = {
    command = "/run/current-system/sw/bin/nix";
    args = [ "run" "nixpkgs#mcp-nixos" ];
  };

  "agentmemory" = {
    command = "/run/current-system/sw/bin/npx";
    args = [ "-y" "@agentmemory/mcp" ];
    env = {
      AGENTMEMORY_URL = "http://localhost:3111";
      AGENTMEMORY_TOOLS = "core";
    };
  };
}
