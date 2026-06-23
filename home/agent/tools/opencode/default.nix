{ lib
, stdenvNoCC
, makeWrapper
, nodejs_22
}:

stdenvNoCC.mkDerivation {
  pname = "opencode";
  version = "npm-latest";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    makeWrapper ${nodejs_22}/bin/npm $out/bin/opencode \
      --set NPM_CONFIG_UPDATE_NOTIFIER false \
      --set NPM_CONFIG_FUND false \
      --add-flags "exec" \
      --add-flags "--yes" \
      --add-flags "--package" \
      --add-flags "opencode-ai@latest" \
      --add-flags "--" \
      --add-flags "opencode"

    runHook postInstall
  '';

  meta = {
    description = "Latest opencode CLI from npm, wrapped for NixOS";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = lib.platforms.linux;
  };
}
