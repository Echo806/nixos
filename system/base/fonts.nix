{ config, pkgs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };

  # WPS 11 on this machine renders some CJK font combinations as solid
  # black/red blocks.  Empirical tests on the affected document showed:
  # - replacing 方正小标宋简体 with 宋体 removes the black title blocks;
  # - replacing 黑体/SimHei with 微软雅黑 removes the red hint blocks.
  # Keep Windows fonts installed, but rewrite these problematic requested
  # families at fontconfig level for WPS/office rendering stability.
  wpsBrokenTitleFontAliases = ''
    <match target="pattern">
      <test name="family" compare="contains"><string>方正小标宋</string></test>
      <edit name="family" mode="assign_replace" binding="strong"><string>宋体</string></edit>
    </match>
    <match target="pattern">
      <test name="family" compare="eq"><string>FZXiaoBiaoSong-B05S</string></test>
      <edit name="family" mode="assign_replace" binding="strong"><string>宋体</string></edit>
    </match>
    <match target="pattern">
      <test name="family" compare="eq"><string>FZ_XiaoBiaoSong</string></test>
      <edit name="family" mode="assign_replace" binding="strong"><string>宋体</string></edit>
    </match>
    <match target="pattern">
      <test name="family" compare="eq"><string>黑体</string></test>
      <edit name="family" mode="assign_replace" binding="strong"><string>微软雅黑</string></edit>
    </match>
    <match target="pattern">
      <test name="family" compare="eq"><string>SimHei</string></test>
      <edit name="family" mode="assign_replace" binding="strong"><string>Microsoft YaHei</string></edit>
    </match>
  '';
in
{
  fonts.packages = fonts.system;
  fonts.fontconfig = {
    defaultFonts = fonts.systemFontconfig;
    localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        ${wpsBrokenTitleFontAliases}
      </fontconfig>
    '';
  };
}
