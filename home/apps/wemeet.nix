
{ config, pkgs, ... }:

let
  wemeetXwaylandDefault = pkgs.symlinkJoin {
    name = "wemeet-xwayland-default";
    paths = [ pkgs.wemeet ];
    postBuild = ''
      ln -sf ${pkgs.wemeet}/bin/wemeet-xwayland $out/bin/wemeet
    '';
  };
in

{
  home.packages = [
    wemeetXwaylandDefault
  ];

  home.file.".local/share/applications/wemeetapp.desktop".text = ''
    [Desktop Entry]
    Name=WemeetApp
    Name[zh_CN]=腾讯会议
    Exec=wemeet-xwayland %u
    Icon=wemeet
    Type=Application
    Terminal=false
    Categories=AudioVideo;
    MimeType=x-scheme-handler/wemeet;
  '';
}
