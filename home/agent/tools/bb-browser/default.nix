{ lib, callPackage, ... }:

callPackage ../cached-tool-wrapper.nix {
  pname = "bb-browser";
  bins = [
    { name = "bb-browser"; }
    { name = "bb-browser-daemon"; }
  ];
  description = "Cached latest bb-browser CLI and daemon, updated by agent-tools-update";
  homepage = "https://github.com/epiral/bb-browser";
  license = lib.licenses.mit;
}
