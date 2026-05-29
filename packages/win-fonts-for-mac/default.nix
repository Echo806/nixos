{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "win-fonts-for-mac";
  version = "2026-05-29";

  src = fetchFromGitHub {
    owner = "BronyaCat";
    repo = "Win-Fonts-For-Mac";
    rev = "441735f619fc6533c4316c0b00fc25c5dd907da3";
    hash = "sha256-ilM8Vd34r8jJprj3Eyd7kUivvgpvdylS0Wk5doS0eOY=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/win-fonts-for-mac
    cp Fonts/msyh.ttc Fonts/msyhbd.ttc Fonts/msyhl.ttc \
      Fonts/国标公文字体/FZXBSJW.TTF \
      Fonts/国标公文字体/Fsong_GB2312.ttf \
      Fonts/国标公文字体/Kaiti_GB2312.ttf \
      Fonts/用于Office的微软雅黑ttf文件/msyh.ttf \
      Fonts/用于Office的微软雅黑ttf文件/msyhbd.ttf \
      Fonts/用于Office的微软雅黑ttf文件/msyhl.ttf \
      $out/share/fonts/truetype/win-fonts-for-mac/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Selected Windows Chinese fonts from BronyaCat/Win-Fonts-For-Mac for WPS/Office compatibility";
    homepage = "https://github.com/BronyaCat/Win-Fonts-For-Mac";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
