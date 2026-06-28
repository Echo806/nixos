{ lib, callPackage, ... }:

callPackage ../cached-tool-wrapper.nix {
  pname = "codex";
  bins = [
    { name = "codex"; }
  ];
  description = "Cached latest OpenAI Codex CLI, updated by agent-tools-update";
  homepage = "https://github.com/openai/codex";
  license = lib.licenses.asl20;
}
