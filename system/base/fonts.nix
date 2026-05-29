{ config, pkgs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
in
{
  fonts.packages = fonts.system;
  fonts.fontconfig = {
    defaultFonts = fonts.systemFontconfig;
    localConf = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <!--
          Office documents often reference Windows/Founder font family names.
          Keep these aliases at fontconfig level so LibreOffice can render common
          Chinese office documents reproducibly without WPS-specific workarounds.
        -->
        <match target="pattern">
          <test name="family" compare="contains"><string>方正小标宋</string></test>
          <edit name="family" mode="assign_replace" binding="strong"><string>宋体</string></edit>
        </match>
        <match target="pattern">
          <test name="family" compare="eq"><string>FZXiaoBiaoSong-B05S</string></test>
          <edit name="family" mode="assign_replace" binding="strong"><string>宋体</string></edit>
        </match>
        <match target="pattern">
          <test name="family" compare="contains"><string>FZXiaoBiaoSong</string></test>
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
      </fontconfig>
    '';
  };
}
