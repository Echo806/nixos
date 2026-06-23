{ lib
, stdenvNoCC
, makeWrapper
, nodejs_22
}:

stdenvNoCC.mkDerivation {
  pname = "claude-code";
  version = "npm-latest";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    makeWrapper ${nodejs_22}/bin/npm $out/bin/claude \
      --set NPM_CONFIG_UPDATE_NOTIFIER false \
      --set NPM_CONFIG_FUND false \
      --add-flags "exec" \
      --add-flags "--yes" \
      --add-flags "--package" \
      --add-flags "@anthropic-ai/claude-code@latest" \
      --add-flags "--" \
      --add-flags "claude"

    runHook postInstall
  '';

  meta = {
    description = "Latest Claude Code CLI from npm, wrapped for NixOS";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = lib.platforms.linux;
  };
}
