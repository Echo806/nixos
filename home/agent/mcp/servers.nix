{
  "mcp-nixos" = {
    command = "/run/current-system/sw/bin/mcp-nixos";
    args = [ ];
  };

  "agentmemory" = {
    command = "/run/current-system/sw/bin/agentmemory-mcp";
    args = [ ];
    env = {
      AGENTMEMORY_URL = "http://localhost:3111";
      AGENTMEMORY_TOOLS = "core";
    };
  };
}
