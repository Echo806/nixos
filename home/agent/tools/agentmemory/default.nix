{ lib
, stdenvNoCC
, makeWrapper
, nodejs_22
}:

stdenvNoCC.mkDerivation {
  pname = "agentmemory";
  version = "npm-latest";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    makeWrapper ${nodejs_22}/bin/npm $out/bin/agentmemory \
      --set NPM_CONFIG_UPDATE_NOTIFIER false \
      --set NPM_CONFIG_FUND false \
      --add-flags "exec" \
      --add-flags "--yes" \
      --add-flags "--package" \
      --add-flags "@agentmemory/agentmemory@latest" \
      --add-flags "--" \
      --add-flags "agentmemory"

    makeWrapper ${nodejs_22}/bin/npm $out/bin/agentmemory-mcp \
      --set NPM_CONFIG_UPDATE_NOTIFIER false \
      --set NPM_CONFIG_FUND false \
      --add-flags "exec" \
      --add-flags "--yes" \
      --add-flags "--package" \
      --add-flags "@agentmemory/mcp@latest" \
      --add-flags "--" \
      --add-flags "agentmemory-mcp"

    runHook postInstall
  '';

  meta = {
    description = "Latest agentmemory CLI and MCP shim from npm, wrapped for NixOS";
    homepage = "https://github.com/rohitg00/agentmemory";
    license = lib.licenses.mit;
    mainProgram = "agentmemory";
    platforms = lib.platforms.linux;
  };
}
