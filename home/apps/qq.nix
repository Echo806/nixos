{ config, pkgs, ... }:
let
  # QQ/Electron 在 Wayland 下右键复制不生效（Chromium bug），
  # 通过 wrapper 强制走 XWayland，右键复制即恢复正常。
  qq-xwayland = pkgs.runCommand "qq-xwayland" { } ''
    mkdir -p $out/bin
    cat > $out/bin/qq << 'WRAPPER'
#!/bin/sh
# 临时清除 Wayland 环境变量，使 qq 包的 wrapper 不添加 Wayland 参数，
# Electron 会 fallback 到 XWayland（:1）。
unset WAYLAND_DISPLAY
exec ${pkgs.qq}/bin/qq "$@"
WRAPPER
    chmod +x $out/bin/qq
  '';
in
{
  home.packages = [ qq-xwayland ];

  # 覆盖 qq.desktop 的 Exec 指向我们的 wrapper
  xdg.desktopEntries.qq = {
    name = "QQ";
    exec = "${qq-xwayland}/bin/qq %U";
    icon = "${pkgs.qq}/share/icons/hicolor/512x512/apps/qq.png";
    terminal = false;
    categories = [ "Network" ];
    comment = "QQ (XWayland)";
    settings.StartupWMClass = "QQ";
  };
}
