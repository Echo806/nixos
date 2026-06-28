{ lib
, stdenvNoCC
, bash
, coreutils
, gnused
, findutils
, nodejs_22
, python3
, uv
}:

let
  runtimePath = lib.makeBinPath [
    bash
    coreutils
    gnused
    findutils
    nodejs_22
    python3
    uv
  ];
in
stdenvNoCC.mkDerivation {
  pname = "agent-tools-update";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cat > $out/bin/agent-tools-update <<'SCRIPT'
    #!${bash}/bin/bash
    set -euo pipefail

    export PATH="${runtimePath}:$PATH"
    export NPM_CONFIG_UPDATE_NOTIFIER=false
    export NPM_CONFIG_FUND=false
    export NPM_CONFIG_PROGRESS=false
    export UV_NO_PROGRESS=true
    export UV_PYTHON_DOWNLOADS=never
    export UV_PYTHON=${python3}/bin/python3

    root="''${AGENT_TOOLS_ROOT:-$HOME/.local/share/agent-tools}"
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/agent-tools"
    npm_prefix="$root/npm"
    uv_root="$root/uv"

    usage() {
      cat <<USAGE
    Usage: agent-tools-update

    Updates cached latest agent tools under:
      ''${AGENT_TOOLS_ROOT:-$HOME/.local/share/agent-tools}

    Extra npm package specs:
      ''${XDG_CONFIG_HOME:-$HOME/.config}/agent-tools/npm-packages.txt

    Extra uv/PyPI tools:
      ''${XDG_CONFIG_HOME:-$HOME/.config}/agent-tools/uv-tools.txt
    USAGE
    }

    if [ "$#" -gt 0 ]; then
      case "$1" in
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
    fi

    read_package_file() {
      local file="$1"
      if [ -f "$file" ]; then
        sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$file" | sed '/^$/d'
      fi
    }

    npm_packages=(
      "@openai/codex@latest"
      "@anthropic-ai/claude-code@latest"
      "opencode-ai@latest"
      "bb-browser@latest"
      "@agentmemory/agentmemory@latest"
      "@agentmemory/mcp@latest"
    )

    while IFS= read -r package; do
      npm_packages+=("$package")
    done < <(read_package_file "$config_dir/npm-packages.txt")

    uv_tools=(
      "cli-anything-hub"
    )

    while IFS= read -r package; do
      uv_tools+=("$package")
    done < <(read_package_file "$config_dir/uv-tools.txt")

    mkdir -p "$root" "$config_dir"

    npm_install_with_retry() {
      local package="$1"
      local attempt=1
      local max_attempts="''${AGENT_TOOLS_NPM_ATTEMPTS:-3}"

      while true; do
        echo "    npm install $package (attempt $attempt/$max_attempts)"
        if npm install \
          --prefix "$tmp/npm" \
          --cache "$root/npm-cache" \
          --no-audit \
          --no-fund \
          --omit=dev \
          --prefer-online \
          --fetch-retries=5 \
          --fetch-retry-factor=2 \
          --fetch-retry-mintimeout=20000 \
          --fetch-retry-maxtimeout=120000 \
          "$package"
        then
          return 0
        fi

        if [ "$attempt" -ge "$max_attempts" ]; then
          echo "    failed after $max_attempts attempts: $package" >&2
          return 1
        fi

        attempt=$((attempt + 1))
        sleep 10
      done
    }

    echo "==> Updating npm-backed agent tools"
    tmp="$(mktemp -d "$root/.npm-update.XXXXXX")"
    cleanup() {
      rm -rf "$tmp"
    }
    trap cleanup EXIT

    mkdir -p "$tmp/npm"
    for package in "''${npm_packages[@]}"; do
      npm_install_with_retry "$package"
    done

    if [ -d "$npm_prefix" ]; then
      backup="$root/npm.previous"
      rm -rf "$backup"
      mv "$npm_prefix" "$backup"
    fi
    mv "$tmp/npm" "$npm_prefix"

    echo "==> Updating uv-backed agent tools"
    export UV_TOOL_DIR="$uv_root/tools"
    export UV_TOOL_BIN_DIR="$uv_root/bin"
    export UV_CACHE_DIR="$uv_root/cache"
    mkdir -p "$UV_TOOL_DIR" "$UV_TOOL_BIN_DIR" "$UV_CACHE_DIR"
    for tool in "''${uv_tools[@]}"; do
      uv tool install --force --python ${python3}/bin/python3 "$tool"
    done

    echo "==> Agent tools installed under $root"
    echo "    Add future npm tools to: $config_dir/npm-packages.txt"
    echo "    Add future uv tools to:  $config_dir/uv-tools.txt"
    SCRIPT
    chmod +x $out/bin/agent-tools-update

    cat > $out/bin/agent-tool <<'SCRIPT'
    #!${bash}/bin/bash
    set -euo pipefail

    export PATH="${runtimePath}:$PATH"

    if [ "$#" -lt 1 ]; then
      echo "Usage: agent-tool <cached-binary> [args...]" >&2
      exit 2
    fi

    root="''${AGENT_TOOLS_ROOT:-$HOME/.local/share/agent-tools}"
    name="$1"
    shift

    for candidate in \
      "$root/npm/node_modules/.bin/$name" \
      "$root/uv/bin/$name"
    do
      if [ -x "$candidate" ]; then
        exec "$candidate" "$@"
      fi
    done

    echo "agent-tool: '$name' is not installed in $root" >&2
    echo "Add its package to ~/.config/agent-tools/npm-packages.txt or uv-tools.txt, then run: agent-tools-update" >&2
    exit 127
    SCRIPT
    chmod +x $out/bin/agent-tool

    runHook postInstall
  '';

  meta = {
    description = "Update and run cached latest agent CLIs outside startup paths";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.mit;
    mainProgram = "agent-tools-update";
    platforms = lib.platforms.unix;
  };
}
