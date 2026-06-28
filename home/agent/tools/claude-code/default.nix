{ lib, callPackage, ... }:

callPackage ../cached-tool-wrapper.nix {
  pname = "claude-code";
  bins = [
    { name = "claude"; }
  ];
  description = "Cached latest Claude Code CLI, updated by agent-tools-update";
  homepage = "https://github.com/anthropics/claude-code";
  license = lib.licenses.unfree;
}
