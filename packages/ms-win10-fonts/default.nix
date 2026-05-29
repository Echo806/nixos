{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "ms-win10-fonts";
  version = "2026-05-29";

  src = fetchFromGitHub {
    owner = "streetsamurai00mi";
    repo = "ttf-ms-win10";
    rev = "417eb232e8d037964971ae2690560a7b12e5f0d4";
    hash = "sha256-UwkHlrSRaXhfoMlimyXFETV9yq1SbvUXykrhigf+wP8=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/ms-win10-fonts
    find . -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' \) -exec cp -v {} $out/share/fonts/truetype/ms-win10-fonts/ \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "Microsoft Windows 10 TrueType fonts from streetsamurai00mi/ttf-ms-win10";
    homepage = "https://github.com/streetsamurai00mi/ttf-ms-win10";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
