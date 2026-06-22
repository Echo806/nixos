{ config, inputs, lib, pkgs, ... }:
let
  agentLib = import ../lib.nix { inherit lib; };
  mcpServers = import ../mcp/servers.nix;
  managedMcpToml = agentLib.renderCodexMcpServers mcpServers;
  python = pkgs.python3.withPackages (ps: [ ps.tomli ps.tomli-w ]);
  unstablePkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    unstablePkgs.codex
    pkgs.nodejs
    pkgs.bb-browser
    pkgs.cli-anything-hub
  ];

  home.file.".codex/managed-mcp.toml".text = managedMcpToml + "\n";

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
