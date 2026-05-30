{ lib
, stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, makeWrapper
, nodejs_22
, pnpm_9
, pnpmConfigHook
,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bb-browser";
  version = "0.14.2-unstable-2026-05-27";

  src = fetchFromGitHub {
    owner = "epiral";
    repo = "bb-browser";
    rev = "7975dc74b3f637d54906228e52f2ba9454874105";
    hash = "sha256-oy9fVeMD06lcejc40aBeR7RR7IGAG6jBx2YJUDwEzIY=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-SzG0dcq18nVEtD/YVu0CZQ1jbrokS+rXxh08oW3+yTc=";
    pnpm = pnpm_9;
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs_22
    pnpm_9
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/bb-browser $out/bin
    cp -R dist web package.json README.md LICENSE node_modules packages $out/lib/bb-browser/
    rm -rf \
      $out/lib/bb-browser/packages/*/src \
      $out/lib/bb-browser/packages/*/tsconfig.json \
      $out/lib/bb-browser/packages/*/tsup.config.ts

    patchShebangs $out/lib/bb-browser/dist $out/lib/bb-browser/node_modules

    makeWrapper ${nodejs_22}/bin/node $out/bin/bb-browser \
      --add-flags $out/lib/bb-browser/dist/cli.js
    makeWrapper ${nodejs_22}/bin/node $out/bin/bb-browser-daemon \
      --add-flags $out/lib/bb-browser/dist/daemon.js

    runHook postInstall
  '';

  meta = {
    description = "CLI for AI agents to control Chrome with your login state";
    homepage = "https://github.com/epiral/bb-browser";
    license = lib.licenses.mit;
    mainProgram = "bb-browser";
    platforms = lib.platforms.linux;
  };
})
