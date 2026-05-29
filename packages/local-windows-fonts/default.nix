{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "local-windows-fonts";
  version = "2026-05-29";

  src = ../../assets/fonts/windows-fonts;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/local-windows-fonts
    find . -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) -exec cp -v {} $out/share/fonts/truetype/local-windows-fonts/ \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "Local Windows Fonts copied from user's Windows Fonts archive";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
