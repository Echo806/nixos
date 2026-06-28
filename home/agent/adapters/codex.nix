{ config, lib, pkgs, ... }:
let
  agentLib = import ../lib.nix { inherit lib; };
  mcpServers = import ../mcp/servers.nix;
  managedMcpToml = agentLib.renderCodexMcpServers mcpServers;
  python = pkgs.python3.withPackages (ps: [ ps.tomli ps.tomli-w ]);
in
{
  home.packages = with pkgs; [
    codex
    nodejs
    bb-browser
    agentmemory
    cli-anything-hub
    agent-tools-update
    nixos-update
  ];

  home.file.".codex/managed-mcp.toml".text = managedMcpToml + "\n";

  home.file.".config/agent-tools/README.md".text = ''
    # Agent tool update lists

    `nixos-update` updates Nix-managed applications, skills, and these cached agent tools.

    Built-in npm tools:
    - @openai/codex@latest
    - @anthropic-ai/claude-code@latest
    - opencode-ai@latest
    - bb-browser@latest
    - @agentmemory/agentmemory@latest
    - @agentmemory/mcp@latest

    Built-in uv tools:
    - cli-anything-hub

    To add future npm-backed agent tools, create or edit:

    ```text
    ~/.config/agent-tools/npm-packages.txt
    ```

    Add one npm package spec per line, for example:

    ```text
    some-agent-cli@latest
    @scope/tool@latest
    ```

    To add future uv/PyPI-backed agent tools, create or edit:

    ```text
    ~/.config/agent-tools/uv-tools.txt
    ```

    Add one package per line, for example:

    ```text
    some-python-cli
    ```

    After editing either file, run:

    ```bash
    agent-tools-update
    ```

    Run an extra cached binary with:

    ```bash
    agent-tool <binary-name>
    ```
  '';

  # Codex discovers SKILL.md files under ~/.codex/skills. Point one native
  # Codex skill root at the normal run user's Hermes skills so user-created or
  # Hermes-installed skills become visible to Codex without copying service
  # runtime state from /var/lib/hermes.
  home.file.".codex/skills/hermes-shared".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.hermes/skills";

  # Keep the user's Codex model/provider/projects intact, but make the MCP
  # section declarative from home/agent/mcp/servers.nix. This avoids replacing
  # ~/.codex/config.toml, which also contains local auth/model preferences.
  home.activation.codexSharedAgentMcp = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -euo pipefail
    config="$HOME/.codex/config.toml"
    managed="$HOME/.codex/managed-mcp.toml"
    mkdir -p "$HOME/.codex"

    ${python}/bin/python - "$config" "$managed" <<'PY'
import pathlib
import sys
import tomli
import tomli_w

config_path = pathlib.Path(sys.argv[1])
managed_path = pathlib.Path(sys.argv[2])

if config_path.exists():
    with config_path.open("rb") as f:
        config = tomli.load(f)
else:
    config = {}

with managed_path.open("rb") as f:
    managed = tomli.load(f)

if not isinstance(config, dict):
    config = {}
config["mcp_servers"] = managed.get("mcp_servers", {})

config_path.write_text(tomli_w.dumps(config))
PY
  '';
}
