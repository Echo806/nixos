# XWayland ↔ Wayland 剪贴板桥接守护进程
# xwayland-satellite 的剪贴板同步有已知问题（GitHub #433），
# 此脚本轮询检测剪贴板变化并双向同步，
# 确保从 QQ/微信（XWayland）复制的文字能粘贴到 Wayland 终端。
{ config, pkgs, ... }:

let
  clipboard-bridge = pkgs.writeShellScript "clipboard-bridge" ''
    set -euo pipefail
    export DISPLAY=":1"
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export WAYLAND_DISPLAY="wayland-1"

    XCLIP="${pkgs.xclip}/bin/xclip"
    WLCOPY="${pkgs.wl-clipboard}/bin/wl-copy"
    WLPASTE="${pkgs.wl-clipboard}/bin/wl-paste"

    last_content=""

    while true; do
      # 读取 X11 剪贴板
      x_content=$("$XCLIP" -selection clipboard -o 2>/dev/null || true)

      if [ -n "$x_content" ] && [ "$x_content" != "$last_content" ]; then
        printf '%s' "$x_content" | "$WLCOPY" --type text/plain;charset=utf-8
        last_content="$x_content"
      fi

      # 读取 Wayland 剪贴板
      wl_content=$("$WLPASTE" -n 2>/dev/null || true)

      if [ -n "$wl_content" ] && [ "$wl_content" != "$last_content" ]; then
        printf '%s' "$wl_content" | "$XCLIP" -selection clipboard -i
        last_content="$wl_content"
      fi

      sleep 0.3
    done
  '';
in
{
  systemd.user.services.clipboard-bridge = {
    description = "XWayland ↔ Wayland clipboard bridge";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${clipboard-bridge}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    wantedBy = [ "graphical-session.target" ];
  };
}
