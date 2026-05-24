{ config, pkgs, inputs, ... }:
let
  hermesDeclarativeState = ../../hermes;

  hermesMemorySeed = pkgs.runCommand "hermes-memory-seed" { } ''
    set -euo pipefail
    mkdir -p "$out/memories"
    cp ${hermesDeclarativeState}/memory/user.md "$out/memories/user.md"
    cp ${hermesDeclarativeState}/memory/memory.md "$out/memories/memory.md"
  '';

  agencyAgents = pkgs.fetchFromGitHub {
    owner = "msitarzewski";
    repo = "agency-agents";
    rev = "783f6a72bfd7f3135700ac273c619d92821b419a";
    hash = "sha256-FMjC1w6631Y4Aiz4O4UW2zK4EDUvOub/dsnxoKto1pw=";
  };

  agencyAgentsHermesSkills = pkgs.runCommand "agency-agents-hermes-skills" { } ''
    set -euo pipefail
    mkdir -p "$out/agency-agents"
    tmp="$TMPDIR/agency-agents-work"
    cp -R ${agencyAgents}/. "$tmp"
    chmod -R u+w "$tmp"
    cd "$tmp"
    ${pkgs.bash}/bin/bash scripts/convert.sh --tool opencode >/dev/null

    for file in integrations/opencode/agents/*.md; do
      slug="$(basename "$file" .md)"
      skill_dir="$out/agency-agents/$slug"
      mkdir -p "$skill_dir"

      name="$(sed -n 's/^name:[[:space:]]*//p' "$file" | head -1)"
      description="$(sed -n 's/^description:[[:space:]]*//p' "$file" | head -1 | sed 's/"/\\"/g')"
      mode="$(sed -n 's/^mode:[[:space:]]*//p' "$file" | head -1)"
      [ -n "$name" ] || name="$slug"
      [ -n "$description" ] || description="Agency agent persona: $name"
      [ -n "$mode" ] || mode="subagent"

      body="$TMPDIR/body-$slug.md"
      awk '
        NR == 1 && $0 == "---" { in_fm=1; next }
        in_fm && $0 == "---" { in_fm=0; next }
        !in_fm { print }
      ' "$file" > "$body"

      cat > "$skill_dir/SKILL.md" <<EOF
---
name: agency-$slug
description: "Agency agent persona: $description"
version: 1.0.0
source: https://github.com/msitarzewski/agency-agents
metadata:
  hermes:
    tags: [agency-agents, persona, opencode, $mode]
---

# $name

This skill loads the \`$name\` agency persona from msitarzewski/agency-agents.
Use it when the user asks for this specialist role/personality, or asks to activate agency agent \`$name\`.

Original converted file: \`integrations/opencode/agents/$slug.md\`

## Persona

EOF
      cat "$body" >> "$skill_dir/SKILL.md"
    done
  '';
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes/.hermes/skills/agency-agents 0755 hermes hermes - -"
    "C+ /var/lib/hermes/.hermes/skills/agency-agents - hermes hermes - ${agencyAgentsHermesSkills}/agency-agents"

    "d /var/lib/hermes/.hermes/skills/custom 0755 hermes hermes - -"
    "C+ /var/lib/hermes/.hermes/skills/custom - hermes hermes - ${hermesDeclarativeState}/skills/custom"

    "d /var/lib/hermes/.hermes/memories 0755 hermes hermes - -"
    "C+ /var/lib/hermes/.hermes/memories - hermes hermes - ${hermesMemorySeed}/memories"

    "C+ /var/lib/hermes/.hermes/SOUL.md 0644 hermes hermes - ${hermesDeclarativeState}/SOUL.md"
  ];

  services.hermes-agent = {
    enable = true;

    settings = {
      model = {
        base_url = "https://openrouter.ai/api/v1";
        default = "deepseek/deepseek-v4-flash:free";
      };
      toolsets = [ "all" ];
      plugins = {
        enabled = [];
      };

      skills = {
        external_dirs = [
          "/var/lib/hermes/.hermes/skills"
        ];
      };

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };

      # MCP servers available to Hermes (declare here to persistently register mcp-nixos)
      mcpServers = {
        "mcp-nixos" = {
          command = "/run/current-system/sw/bin/nix";
          args = [ "run" "nixpkgs#mcp-nixos" ];
        };
      };
    };

    # 密钥走环境文件（/var/lib/hermes/env），不在 Git 中跟踪
    environmentFiles = [ "/var/lib/hermes/env" ];

    addToSystemPackages = true;
  };
}
