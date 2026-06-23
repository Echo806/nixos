{ inputs, pkgs }:
let
  agencyAgents = inputs.agency-agents;
  superpowers = inputs.superpowers;
  anthropicOfficialSkills = inputs.anthropic-skills;
  openaiOfficialSkills = inputs.openai-skills;

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
  inherit agencyAgentsHermesSkills officeDocumentSkills superpowers;
}
