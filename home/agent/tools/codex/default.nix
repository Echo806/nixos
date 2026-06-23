{ lib
, stdenvNoCC
, makeWrapper
, nodejs_22
}:

stdenvNoCC.mkDerivation {
  pname = "codex";
  version = "npm-latest";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    makeWrapper ${nodejs_22}/bin/npm $out/bin/codex \
      --set NPM_CONFIG_UPDATE_NOTIFIER false \
      --set NPM_CONFIG_FUND false \
      --add-flags "exec" \
      --add-flags "--yes" \
      --add-flags "--package" \
      --add-flags "@openai/codex@latest" \
      --add-flags "--" \
      --add-flags "codex"

    runHook postInstall
  '';

  meta = {
    description = "Latest OpenAI Codex CLI from npm, wrapped for NixOS";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = lib.platforms.linux;
  };
}
