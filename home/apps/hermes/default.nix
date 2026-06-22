{ lib, pkgs, ... }:

let
  mcpServers = import ../../agent/mcp/servers.nix;
  managedMcpYaml = builtins.toJSON { mcp_servers = mcpServers; };
in

{
  home.file.".hermes/managed-mcp.yaml".text = managedMcpYaml + "\n";

  # Declaratively enforce Hermes CLI prompt-timeout preferences for the normal
  # run user's ~/.hermes/config.yaml and shared MCP servers without replacing
  # the rest of the config (model/provider secrets remain in the local config
  # or env files, not in git).
  home.activation.hermesSharedAgentConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -euo pipefail
    config="$HOME/.hermes/config.yaml"
    managed="$HOME/.hermes/managed-mcp.yaml"
    mkdir -p "$HOME/.hermes"

    ${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python - "$config" "$managed" <<'PY'
import pathlib
import sys
import yaml

path = pathlib.Path(sys.argv[1])
managed_path = pathlib.Path(sys.argv[2])
if path.exists():
    data = yaml.safe_load(path.read_text()) or {}
else:
    data = {}
if not isinstance(data, dict):
    data = {}

# Hermes currently exposes timeouts for these prompts, but not a separate
# "hide countdown" switch. Use the largest signed 32-bit integer so the TUI
# prompt effectively waits indefinitely and the visible countdown is no longer
# meaningful while preserving safety confirmations.
no_countdown_timeout = 2147483647

approvals = data.setdefault("approvals", {})
if not isinstance(approvals, dict):
    approvals = {}
    data["approvals"] = approvals
approvals["timeout"] = no_countdown_timeout
approvals.setdefault("mode", "manual")
approvals.setdefault("cron_mode", "deny")
approvals.setdefault("mcp_reload_confirm", True)
approvals.setdefault("destructive_slash_confirm", True)

clarify = data.setdefault("clarify", {})
if not isinstance(clarify, dict):
    clarify = {}
    data["clarify"] = clarify
clarify["timeout"] = no_countdown_timeout

with managed_path.open() as f:
    managed = yaml.safe_load(f) or {}
if not isinstance(managed, dict):
    managed = {}
data["mcp_servers"] = managed.get("mcp_servers", {})
# Hermes' native MCP client reads mcp_servers. Drop a stale camelCase key if a
# previous config writer produced one, so the active config is unambiguous.
data.pop("mcpServers", None)

path.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False))
PY
  '';
}
