{ lib
, stdenvNoCC
, bash
, coreutils
, git
, nix
, systemd
, agent-tools-update
}:

let
  runtimePath = lib.makeBinPath [
    bash
    coreutils
    git
    nix
    systemd
    agent-tools-update
  ];
in
stdenvNoCC.mkDerivation {
  pname = "nixos-update";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cat > $out/bin/nixos-update <<'SCRIPT'
    #!${bash}/bin/bash
    set -euo pipefail

    export PATH="${runtimePath}:/run/current-system/sw/bin:$PATH"

    flake="''${NIXOS_UPDATE_FLAKE:-/home/run/nixos}"
    host="''${NIXOS_UPDATE_HOST:-$(uname -n | cut -d. -f1)}"
    mode="switch"

    usage() {
      cat <<USAGE
    Usage: nixos-update [--dry-build] [--no-switch] [--host HOST]

    Updates:
      - Nix flake inputs for Nix-managed apps, system config, and skills
      - Cached latest agent tools via agent-tools-update
      - The current NixOS generation, unless --no-switch is passed
    USAGE
    }

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --dry-build)
          mode="dry-build"
          shift
          ;;
        --no-switch)
          mode="no-switch"
          shift
          ;;
        --host)
          host="''${2:-}"
          if [ -z "$host" ]; then
            echo "--host requires a value" >&2
            exit 2
          fi
          shift 2
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown argument: $1" >&2
          usage >&2
          exit 2
          ;;
      esac
    done

    cd "$flake"

    echo "==> Current NixOS config status"
    git status --short || true

    echo "==> Updating flake inputs for apps, system config, and skills"
    nix flake update --flake "$flake"

    echo "==> Updating cached latest agent tools"
    agent-tools-update

    echo "==> Evaluating NixOS configuration: $host"
    nixos-rebuild dry-build --flake "$flake#$host"

    if [ "$mode" = "dry-build" ] || [ "$mode" = "no-switch" ]; then
      echo "==> Skipping switch because mode is $mode"
      exit 0
    fi

    echo "==> Switching NixOS configuration: $host"
    sudo nixos-rebuild switch --flake "$flake#$host"

    if systemctl --user list-unit-files agentmemory.service >/dev/null 2>&1; then
      echo "==> Restarting agentmemory user service"
      systemctl --user restart agentmemory.service || true
    fi

    echo "==> Update complete"
    SCRIPT
    chmod +x $out/bin/nixos-update

    runHook postInstall
  '';

  meta = {
    description = "One command to update Nix-managed apps, skills, config, and cached agent tools";
    homepage = "https://nixos.org";
    license = lib.licenses.mit;
    mainProgram = "nixos-update";
    platforms = lib.platforms.linux;
  };
}
