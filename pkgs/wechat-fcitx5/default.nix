{ pkgs, makeWrapper, ... }:

let
  pname = "wechat";
  version = "4.1.1.4";

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version;
    src = pkgs.fetchurl {
      url = "https://web.archive.org/web/20260311102439if_/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
      hash = "sha256-XxAvFnlljqurGPDgRr+DnuCKbdVvgXBPh02DLHY3Oz8=";
    };
    postExtract = ''
      patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat
    '';
  };

  gtkImModuleCache = pkgs.runCommand "wechat-fcitx5-gtk-immodules.cache"
    {
      nativeBuildInputs = [ pkgs.gtk3.dev ];
    }
    ''
      mkdir -p $out/etc/gtk-3.0
      gtk-query-immodules-3.0 ${pkgs.fcitx5-gtk}/lib/gtk-3.0/3.0.0/immodules/im-fcitx5.so \
        > $out/etc/gtk-3.0/immodules.cache
    '';
in
pkgs.appimageTools.wrapAppImage {
  inherit pname version;

  nativeBuildInputs = [ makeWrapper ];

  src = appimageContents;

  extraPkgs = fhsPkgs: with fhsPkgs; [
    fcitx5-gtk
    libsForQt5.fcitx5-qt
    qt6Packages.fcitx5-qt
  ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${appimageContents}/wechat.desktop $out/share/applications/
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

    substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat

    wrapProgram $out/bin/wechat \
      --set GTK_IM_MODULE fcitx \
      --set QT_IM_MODULE fcitx \
      --set XMODIFIERS @im=fcitx \
      --set INPUT_METHOD fcitx \
      --set GTK_IM_MODULE_FILE ${gtkImModuleCache}/etc/gtk-3.0/immodules.cache
  '';

  meta = pkgs.wechat.meta;
}
