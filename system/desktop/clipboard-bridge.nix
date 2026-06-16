# XWayland ↔ Wayland 剪贴板桥接守护进程
# xwayland-satellite 的剪贴板同步有已知问题（GitHub #433），
# 此脚本轮询检测剪贴板变化并双向同步。
# 注意：必须按 MIME 类型同步；截图是 image/png，不能当 UTF-8 文本读写，
# 否则粘贴到 XWayland 微信/QQ 时会变成二进制乱码。
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
    SHA256SUM="${pkgs.coreutils}/bin/sha256sum"
    MKTEMP="${pkgs.coreutils}/bin/mktemp"
    RM="${pkgs.coreutils}/bin/rm"
    SLEEP="${pkgs.coreutils}/bin/sleep"
    TR="${pkgs.coreutils}/bin/tr"
    HEAD="${pkgs.coreutils}/bin/head"
    GREP="${pkgs.gnugrep}/bin/grep"

    state_dir="$($MKTEMP -d)"
    trap '"$RM" -rf "$state_dir"' EXIT

    last_source=""
    last_hash=""

    hash_file() {
      "$SHA256SUM" "$1" | "$HEAD" -c 64
    }

    has_wl_type() {
      "$WLPASTE" --list-types 2>/dev/null | "$GREP" -Fxq "$1"
    }

    has_x_type() {
      "$XCLIP" -selection clipboard -t TARGETS -o 2>/dev/null | "$TR" '\0' '\n' | "$GREP" -Fxq "$1"
    }

    sync_wl_to_x() {
      local tmp="$state_dir/wl"

      # Niri/xdg-desktop-portal screenshots put PNG bytes on the Wayland clipboard.
      # Forward them as image/png to X11 so XWayland apps such as WeChat paste an image,
      # not UTF8_STRING garbage.
      if has_wl_type image/png; then
        if "$WLPASTE" --type image/png -n > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          local hash="image/png:$(hash_file "$tmp")"
          if [ "$hash" != "$last_hash" ]; then
            "$XCLIP" -selection clipboard -t image/png -i "$tmp"
            last_source="wl"
            last_hash="$hash"
          fi
        fi
        return
      fi

      # Text only. Do not call plain wl-paste on arbitrary binary clipboards.
      if has_wl_type 'text/plain;charset=utf-8' || has_wl_type text/plain || has_wl_type UTF8_STRING; then
        if "$WLPASTE" --type text/plain -n > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          local hash="text:$(hash_file "$tmp")"
          if [ "$hash" != "$last_hash" ]; then
            "$XCLIP" -selection clipboard -t UTF8_STRING -i "$tmp"
            last_source="wl"
            last_hash="$hash"
          fi
        fi
      fi
    }

    sync_x_to_wl() {
      local tmp="$state_dir/x"

      if has_x_type image/png; then
        if "$XCLIP" -selection clipboard -t image/png -o > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          local hash="image/png:$(hash_file "$tmp")"
          if [ "$hash" != "$last_hash" ]; then
            "$WLCOPY" --type image/png < "$tmp"
            last_source="x"
            last_hash="$hash"
          fi
        fi
        return
      fi

      if has_x_type UTF8_STRING || has_x_type text/plain || has_x_type STRING; then
        if "$XCLIP" -selection clipboard -t UTF8_STRING -o > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          local hash="text:$(hash_file "$tmp")"
          if [ "$hash" != "$last_hash" ]; then
            "$WLCOPY" --type text/plain;charset=utf-8 < "$tmp"
            last_source="x"
            last_hash="$hash"
          fi
        fi
      fi
    }

    while true; do
      sync_x_to_wl || true
      sync_wl_to_x || true
      "$SLEEP" 0.3
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
