{ lib, callPackage, ... }:

callPackage ../cached-tool-wrapper.nix {
  pname = "opencode";
  bins = [
    { name = "opencode"; }
  ];
  description = "Cached latest opencode CLI, updated by agent-tools-update";
  homepage = "https://opencode.ai";
  license = lib.licenses.mit;
}
