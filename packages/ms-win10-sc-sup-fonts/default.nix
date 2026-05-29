{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "ms-win10-sc-sup-fonts";
  version = "2026-05-29";

  src = fetchFromGitHub {
    owner = "chillcicada";
    repo = "ttf-ms-win10-sc-sup";
    rev = "f5d2ef2c84e8979b322563a53ea3adb5ab995176";
    hash = "sha256-gIMRE1jOEtskRzXGdUr6DRXghpMdM37NtoEJsC80/MQ=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/ms-win10-sc-sup-fonts
    cp Deng.ttf Dengb.ttf Dengl.ttf simfang.ttf simhei.ttf simkai.ttf $out/share/fonts/truetype/ms-win10-sc-sup-fonts/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Microsoft Windows 10/11 Simplified Chinese supplemental fonts";
    homepage = "https://github.com/chillcicada/ttf-ms-win10-sc-sup";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
