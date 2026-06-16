{ config, pkgs, inputs, ... }:
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
  users.groups.hermes = { };
  users.users.hermes = {
    isSystemUser = true;
    group = "hermes";
    home = "/var/lib/hermes";
    createHome = true;
  };

  imports = [
    inputs.hermes-agent.nixosModules.default
    ../agent/tools/bb-browser/daemon-service.nix
  ];

  systemd.tmpfiles.rules = [
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

  services.hermes-agent = {
    # The user no longer wants QQ/social-media integration, so do not run the
    # always-on messaging gateway service. Keep CLI/config/skills below managed
    # explicitly for normal local Hermes use.
    enable = false;

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
      approvals = {
        mode = "manual";
        # Keep dangerous-command approval prompts, but remove the practical
        # countdown by making the timeout effectively infinite.
        timeout = 2147483647;
        cron_mode = "deny";
        mcp_reload_confirm = true;
        destructive_slash_confirm = true;
      };
      clarify.timeout = 2147483647;
      inherit mcpServers;
    };

    # 密钥走环境文件（/var/lib/hermes/env），不在 Git 中跟踪
    environmentFiles = [ "/var/lib/hermes/env" ];
  };

  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.bb-browser
    pkgs.cli-anything-hub
    pkgs.google-chrome
    chrome-remote
  ];
}
