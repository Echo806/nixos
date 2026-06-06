{ pkgs, inputs }:
let
  state = ./.;
  skills = import ../agent/skills { inherit pkgs; };
  mcpServers = import ../agent/mcp/servers.nix;

  memorySeed = pkgs.runCommand "hermes-memory-seed" { } ''
    set -euo pipefail
    mkdir -p "$out/memories"
    cp ${state}/memory/user.md "$out/memories/user.md"
    cp ${state}/memory/memory.md "$out/memories/memory.md"
  '';

  chrome-remote = pkgs.callPackage ../agent/tools/bb-browser/chrome-wrapper.nix { };
in
{
  tmpfilesRules = [
    "d /var/lib/hermes 0755 hermes hermes - -"
    "d /var/lib/hermes/.hermes 0755 hermes hermes - -"
    "d /var/lib/hermes/.hermes/skills 0755 hermes hermes - -"
    "R /var/lib/hermes/.hermes/skills/agency-agents - - - - -"
    "C+ /var/lib/hermes/.hermes/skills/agency-agents - hermes hermes - ${skills.agencyAgentsHermesSkills}/agency-agents"
    "R /var/lib/hermes/.hermes/skills/superpowers - - - - -"
    "C+ /var/lib/hermes/.hermes/skills/superpowers - hermes hermes - ${skills.superpowers}/skills"
    "R /var/lib/hermes/.hermes/skills/official-office - - - - -"
    "C+ /var/lib/hermes/.hermes/skills/official-office - hermes hermes - ${skills.officeDocumentSkills}/official-office"
    "R /var/lib/hermes/.hermes/skills/custom - - - - -"
    "C+ /var/lib/hermes/.hermes/skills/custom - hermes hermes - ${state}/skills/custom"
    "R /var/lib/hermes/.hermes/memories - - - - -"
    "C+ /var/lib/hermes/.hermes/memories - hermes hermes - ${memorySeed}/memories"
    "C+ /var/lib/hermes/.hermes/SOUL.md 0644 hermes hermes - ${state}/SOUL.md"
    # Remove stale manually-created gateway locks. The gateway recreates this as hermes.
    "r /var/lib/hermes/.hermes/gateway.lock - - - - -"
  ];

  settings = {
    model = {
      base_url = "https://openrouter.ai/api/v1";
      default = "deepseek/deepseek-v4-flash:free";
    };
    toolsets = [ "all" ];
    plugins.enabled = [ ];
    skills.external_dirs = [ "/var/lib/hermes/.hermes/skills" ];
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
    };
    inherit mcpServers;
  };

  packages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.bb-browser
    pkgs.google-chrome
    chrome-remote
  ];
}
