{ config, pkgs, ... }:

let
  wechatWithFcitx5 = pkgs.callPackage ../../pkgs/wechat-fcitx5 { };
in
{
  home.packages = [
    wechatWithFcitx5
  ];
}
