{ lib, callPackage, ... }:

callPackage ./cached-tool-wrapper.nix {
  pname = "cli-anything-hub";
  bins = [
    {
      name = "cli-hub";
      cache = "uv";
    }
  ];
  description = "Cached latest CLI-Anything hub, updated by agent-tools-update";
  homepage = "https://clianything.cc";
  license = lib.licenses.mit;
  supportedPlatforms = lib.platforms.unix;
}
