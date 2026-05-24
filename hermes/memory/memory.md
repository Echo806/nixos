# Hermes reusable environment memory seed

This file is Git-managed source-of-truth for stable operating conventions that should be reproducible across x250 and runrun.

- NixOS configuration work follows the reproducibility principle: prefer editing Nix files and applying `nixos-rebuild switch` over imperative runtime changes.
- Hermes service configuration belongs in `/home/run/nixos/system/services/hermes-agent.nix` via `services.hermes-agent.*`.
- Runtime files under `/var/lib/hermes/.hermes` are treated as generated state unless explicitly copied from this Git-managed `hermes/` directory by Nix.
- MCP servers for Hermes should be declared in `services.hermes-agent.settings.mcpServers`.
- The NixOS MCP server is declared as `mcp-nixos` using `/run/current-system/sw/bin/nix` with args `[ "run" "nixpkgs#mcp-nixos" ]`.
- Flake host targets are explicit attributes. Use `#x250` for the ThinkPad X250 and `#runrun` for the runrun machine; do not infer the target from the current `hostname` if it says `nixos`.
