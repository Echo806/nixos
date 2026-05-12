{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "wps-symbol-fonts";
  version = "unstable-2023-11-24";

  src = fetchFromGitHub {
    owner = "jayknoxqu";
    repo = "wps-symbol-fonts";
    rev = "7e7a18a51efcfc86a00cf2573a3896eb28fe4a37";
    hash = "sha256-b0Qf1HbQzy2FSd7CJnPAaNpJ0VJT88trMaXuAkXX/OE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp *.ttf $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = with lib; {
    description = "WPS Office symbol fonts (Wingdings, Webdings, Symbol, MT Extra)";
    homepage = "https://github.com/jayknoxqu/wps-symbol-fonts";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
