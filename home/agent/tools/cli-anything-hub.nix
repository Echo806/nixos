{ lib
, stdenvNoCC
, makeWrapper
, python3
, uv
}:

stdenvNoCC.mkDerivation {
  pname = "cli-anything-hub";
  version = "pypi-latest";

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    makeWrapper ${uv}/bin/uv $out/bin/cli-hub \
      --set UV_NO_PROGRESS true \
      --set UV_PYTHON_DOWNLOADS never \
      --set UV_PYTHON ${python3}/bin/python3 \
      --add-flags "tool" \
      --add-flags "run" \
      --add-flags "--no-config" \
      --add-flags "--from" \
      --add-flags "cli-anything-hub@latest" \
      --add-flags "cli-hub"

    runHook postInstall
  '';

  meta = {
    description = "Latest CLI-Anything hub from PyPI, wrapped for NixOS";
    homepage = "https://clianything.cc";
    license = lib.licenses.mit;
    mainProgram = "cli-hub";
    platforms = lib.platforms.unix;
  };
}
