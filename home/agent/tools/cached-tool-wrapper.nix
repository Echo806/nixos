{ lib
, stdenvNoCC
, bash
, coreutils
, nodejs_22
, python3
, uv
, pname
, bins
, description
, homepage
, license
, version ? "cached-latest"
, supportedPlatforms ? lib.platforms.linux
}:

let
  runtimePath = lib.makeBinPath [
    bash
    coreutils
    nodejs_22
    python3
    uv
  ];

  firstBin = (builtins.head bins).name;

  wrapperFor = bin:
    let
      cache = bin.cache or "npm";
      target = bin.target or bin.name;
      toolPath =
        if cache == "uv"
        then "uv/bin/${target}"
        else "npm/node_modules/.bin/${target}";
    in
    ''
      cat > $out/bin/${bin.name} <<'WRAPPER'
      #!${bash}/bin/bash
      set -euo pipefail

      export PATH="${runtimePath}:$PATH"
      export NPM_CONFIG_UPDATE_NOTIFIER=false
      export NPM_CONFIG_FUND=false
      export UV_NO_PROGRESS=true
      export UV_PYTHON_DOWNLOADS=never
      export UV_PYTHON=${python3}/bin/python3

      root="''${AGENT_TOOLS_ROOT:-$HOME/.local/share/agent-tools}"
      tool="$root/${toolPath}"
      if [ ! -x "$tool" ]; then
        echo "${bin.name}: cached agent tool is not installed at $tool" >&2
        echo "Run: agent-tools-update" >&2
        exit 127
      fi

      exec "$tool" "$@"
      WRAPPER
      chmod +x $out/bin/${bin.name}
    '';
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ${lib.concatMapStrings wrapperFor bins}

    runHook postInstall
  '';

  meta = {
    inherit description homepage license;
    mainProgram = firstBin;
    platforms = supportedPlatforms;
  };
}
