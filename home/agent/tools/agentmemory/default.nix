{ lib, callPackage, ... }:

callPackage ../cached-tool-wrapper.nix {
  pname = "agentmemory";
  bins = [
    { name = "agentmemory"; }
    { name = "agentmemory-mcp"; }
  ];
  description = "Cached latest agentmemory CLI and MCP shim, updated by agent-tools-update";
  homepage = "https://github.com/rohitg00/agentmemory";
  license = lib.licenses.mit;
}
