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

  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "f2cbfbefebbfef77321e4c9abc9e949826bea9d7";
    hash = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };

  anthropicOfficialSkills = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "690f15cac7f7b4c055c5ab109c79ed9259934081";
    hash = "sha256-GMXFJSePrpEvhzMQ82YI9Z10BDkuFK/lXUDELclvQ4c=";
  };

  openaiOfficialSkills = pkgs.fetchFromGitHub {
    owner = "openai";
    repo = "skills";
    rev = "b0401f07213a66414d84a65cb50c1d226f99485a";
    hash = "sha256-MpXYiPBzQTBCXN7Hw36qBG82cKqW9havnbCw7JHeSJI=";
  };

  officeDocumentSkills = pkgs.runCommand "hermes-office-document-skills" { } ''
    set -euo pipefail
    mkdir -p "$out/official-office"

    cp -R ${anthropicOfficialSkills}/skills/docx "$out/official-office/docx"
    cp -R ${anthropicOfficialSkills}/skills/xlsx "$out/official-office/xlsx"
    cp -R ${anthropicOfficialSkills}/skills/pptx "$out/official-office/pptx"
    cp -R ${openaiOfficialSkills}/skills/.curated/pdf "$out/official-office/pdf"
  '';

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
    "C+ /var/lib/hermes/.hermes/skills/agency-agents - hermes hermes - ${agencyAgentsHermesSkills}/agency-agents"

    "C+ /var/lib/hermes/.hermes/skills/superpowers - hermes hermes - ${superpowers}/skills"

    "C+ /var/lib/hermes/.hermes/skills/official-office - hermes hermes - ${officeDocumentSkills}/official-office"

    "C+ /var/lib/hermes/.hermes/skills/custom - hermes hermes - ${hermesDeclarativeState}/skills/custom"

    "d /var/lib/hermes/.hermes/memories 0755 hermes hermes - -"
    "C+ /var/lib/hermes/.hermes/memories - hermes hermes - ${hermesMemorySeed}/memories"

    "C+ /var/lib/hermes/.hermes/SOUL.md 0644 hermes hermes - ${hermesDeclarativeState}/SOUL.md"

    # Remove stale manually-created gateway locks.  The gateway recreates the
    # file as the hermes user; keeping this declarative avoids a root-owned lock
    # crash-loop after rebuilds.
    "r /var/lib/hermes/.hermes/gateway.lock - - - - -"
  ];

  services.hermes-agent = {
    # The user no longer wants QQ/social-media integration, so do not run the
    # always-on messaging gateway service.  Keep CLI/config/skills below managed
    # explicitly for normal local Hermes use.
    enable = false;

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
  };

  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  environment.variables = {
    HERMES_HOME = "/var/lib/hermes/.hermes";
  };
}
