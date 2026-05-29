{ lib, stdenvNoCC, noto-fonts-cjk-serif, source-han-sans, source-han-serif }:

stdenvNoCC.mkDerivation {
  pname = "wps-cjk-font-aliases";
  version = "1.0";

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild
    mkdir -p generated
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/SimSun.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/NSimSun.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/FangSong.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/FangSong_GB2312.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/KaiTi.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/KaiTi_GB2312.ttc
    # Do not synthesize Founder font files by renaming Noto fonts here.
    # WPS may render some synthetic/renamed CJK faces as solid black/red blocks.
    # Real Windows/Office fonts from local-windows-fonts should win instead.
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/STSong.ttc
    ln -s ${noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc generated/STZhongsong.ttc
    ln -s ${source-han-sans}/share/fonts/opentype/source-han-sans/SourceHanSans.ttc generated/SimHei.ttc
    ln -s ${source-han-sans}/share/fonts/opentype/source-han-sans/SourceHanSans.ttc generated/DengXian.ttc
    ln -s ${source-han-serif}/share/fonts/opentype/source-han-serif/SourceHanSerif.ttc generated/STFangsong.ttc
    ln -s ${source-han-serif}/share/fonts/opentype/source-han-serif/SourceHanSerif.ttc generated/STKaiti.ttc
    ln -s ${source-han-serif}/share/fonts/opentype/source-han-serif/SourceHanSerif.ttc generated/FZSong.ttc
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp -P generated/* $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Font files renamed to common Microsoft/WPS Chinese font family names for WPS Office compatibility";
    license = licenses.ofl;
    platforms = platforms.linux;
  };
}
