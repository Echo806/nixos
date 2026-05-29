{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "windows-fonts";
  version = "2026-05-29";

  src = ../packages/windows-fonts;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/windows-fonts
    find . -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) -exec cp -v {} $out/share/fonts/truetype/windows-fonts/ \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows fonts copied from user's Windows Fonts archive";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
