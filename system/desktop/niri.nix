{ config, pkgs, ... }:

let
  trayNiriFocus = pkgs.writeShellApplication {
    name = "tray-niri-focus";
    runtimeInputs = [
      pkgs.niri
      pkgs.python3
    ];
    text = ''
      exec python3 - "$@" <<'PY'
      import glob
      import json
      import os
      import re
      import subprocess
      import sys
      import time

      APP_ALIASES = {
          "tray-icon-tray-app-main": ["clash-verge", "clash-verge-rev"],
          "tray-icon-main-1": ["clash-verge", "clash-verge-rev"],
          "tray-icon": ["clash-verge", "clash-verge-rev"],
          "icon-1": ["clash-verge", "clash-verge-rev"],
          "clash-verge": ["clash-verge", "clash-verge-rev"],
          "clashverge": ["clash-verge", "clash-verge-rev"],
          "clash-verge-rev": ["clash-verge", "clash-verge-rev"],
          "chrome-status-icon-1": ["qq"],
          "qq": ["qq"],
          "sunshine": ["sunshine"],
          "wechat": ["wechat"],
      }

      LAUNCHERS = {
          "clash-verge": ["clash-verge"],
          "clash-verge-rev": ["clash-verge"],
      }

      def normalized(value):
          return re.sub(r"[^a-z0-9]+", "-", (value or "").lower()).strip("-")

      def expand_candidates(values):
          candidates = []
          for value in values:
              name = normalized(value)
              if not name:
                  continue
              candidates.extend(APP_ALIASES.get(name, []))
              candidates.append(name)
          seen = set()
          return [x for x in candidates if not (x in seen or seen.add(x))]

      def env_with_niri_socket():
          env = os.environ.copy()
          runtime_dir = env.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
          env["XDG_RUNTIME_DIR"] = runtime_dir
          if not env.get("NIRI_SOCKET") or not os.path.exists(env["NIRI_SOCKET"]):
              sockets = sorted(glob.glob(os.path.join(runtime_dir, "niri.*.sock")))
              if sockets:
                  env["NIRI_SOCKET"] = sockets[0]
          return env

      def run(args, **kwargs):
          return subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, **kwargs)

      def focus(candidates):
          env = env_with_niri_socket()
          wanted = {normalized(candidate) for candidate in candidates}
          for _ in range(12):
              result = run(["niri", "msg", "-j", "windows"], env=env)
              try:
                  windows = json.loads(result.stdout)
              except json.JSONDecodeError:
                  windows = []
              for window in windows:
                  app_id = normalized(window.get("app_id"))
                  title = normalized(window.get("title"))
                  if app_id in wanted or title in wanted:
                      window_id = str(window["id"])
                      run(["niri", "msg", "action", "focus-window", "--id", window_id], env=env)
                      run(["niri", "msg", "action", "unset-window-urgent", "--id", window_id], env=env)
                      return True
              time.sleep(0.15)
          return False

      candidates = expand_candidates(sys.argv[1:])
      if not candidates:
          raise SystemExit(0)
      if focus(candidates):
          raise SystemExit(0)

      for candidate in candidates:
          launcher = LAUNCHERS.get(normalized(candidate))
          if launcher:
              subprocess.Popen(launcher, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
              focus(candidates)
              break
      PY
    '';
  };

  trayNiriActivation = pkgs.writeShellApplication {
    name = "tray-niri-activation";
    runtimeInputs = [
      pkgs.dbus
      pkgs.systemd
      pkgs.niri
      pkgs.python3
      trayNiriFocus
    ];
    text = ''
      exec python3 - <<'PY'
      import re
      import subprocess
      import time

      IGNORE_IDS = {
          "fcitx", "nm-applet", "network", "bluetooth", "volume", "pulseaudio",
      }

      def run(args):
          return subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

      def normalized(value):
          return re.sub(r"[^a-z0-9]+", "-", (value or "").lower()).strip("-")

      def prop(service, path, name):
          result = run(["busctl", "--user", "get-property", service, path, "org.kde.StatusNotifierItem", name])
          match = re.search(r'"([^"]*)"', result.stdout)
          return match.group(1) if match else ""

      def registered_items():
          result = run([
              "busctl", "--user", "get-property",
              "org.kde.StatusNotifierWatcher",
              "/StatusNotifierWatcher",
              "org.kde.StatusNotifierWatcher",
              "RegisteredStatusNotifierItems",
          ])
          return re.findall(r'"([^"/]+)(/[^" ]+)"', result.stdout)

      def tray_targets():
          targets = {}
          for service, path in registered_items():
              raw_id = prop(service, path, "Id")
              raw_title = prop(service, path, "Title")
              names = [normalized(raw_id), normalized(raw_title)]
              if all(not name for name in names):
                  continue
              if any(name in IGNORE_IDS for name in names):
                  continue
              targets[service] = [raw_title, raw_id, service, path]
          return targets

      targets = tray_targets()
      last_refresh = 0.0
      monitor = subprocess.Popen(
          ["dbus-monitor", "--session", "type='method_call',interface='org.kde.StatusNotifierItem'"],
          text=True,
          stdout=subprocess.PIPE,
          stderr=subprocess.DEVNULL,
      )

      assert monitor.stdout is not None
      for line in monitor.stdout:
          match = re.search(r'destination=([^ ]+)', line)
          if not match:
              continue
          destination = match.group(1)
          now = time.monotonic()
          if destination not in targets or now - last_refresh > 10:
              targets = tray_targets()
              last_refresh = now
          candidates = targets.get(destination, [])
          if candidates:
              subprocess.Popen(["tray-niri-focus", *candidates], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
      PY
    '';
  };
in
{
  services.xserver.enable = true;

  environment.systemPackages = [
    pkgs.warpd
    trayNiriFocus
    trayNiriActivation
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.displayManager.sddm.enable = true;

  security.pam.services.sddm.enableGnomeKeyring = true;

  services.displayManager.sessionPackages = [ pkgs.niri ];

  programs.niri.enable = true;

  environment.etc."niri/config.kdl".text = ''
    // 输入设备
    input {
        touchpad {
            tap
            natural-scroll
        }
    }

    // 自启动
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "tray-niri-activation"
    spawn-at-startup "noctalia-shell"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "polkit-gnome-authentication-agent-1"
    spawn-at-startup "nm-applet"
    spawn-at-startup "clash-verge"

    // Wayland 输入法环境变量
    environment {
        GTK_IM_MODULE "fcitx5"
        QT_IM_MODULE "fcitx5"
        SDL_IM_MODULE "fcitx5"
        GLFW_IM_MODULE "ibus"
        XMODIFIERS "@im=fcitx5"
        INPUT_METHOD "fcitx5"
    }

    binds {
        // ── Noctalia IPC ──
        Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
        Mod+Escape { spawn "noctalia-shell" "ipc" "call" "sessionMenu" "toggle"; }
        Mod+L { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
        XF86AudioLowerVolume { spawn "noctalia-shell" "ipc" "call" "volume" "decrease"; }
        XF86AudioRaiseVolume { spawn "noctalia-shell" "ipc" "call" "volume" "increase"; }
        XF86AudioMute { spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }
        XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
        XF86MonBrightnessUp { spawn "noctalia-shell" "ipc" "call" "brightness" "increase"; }

        // ── warpd 虚拟指针 ──
        Mod+Alt+X { spawn "warpd" "--hint"; }
        Mod+Alt+G { spawn "warpd" "--grid"; }
        Mod+Alt+C { spawn "warpd" "--normal"; }

        // ── Launch ──
        Mod+T { spawn "ghostty"; }
        Mod+B { spawn "google-chrome-stable"; }
        // ── Window ──
        Mod+Q { close-window; }
        Mod+Shift+E { quit; }

        // ── Focus ──
        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+Home { focus-column-first; }
        Mod+End { focus-column-last; }

        // ── Move ──
        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }

        // ── Workspace ──
        Mod+U { focus-workspace-up; }
        Mod+D { focus-workspace-down; }
        Mod+Ctrl+U { move-window-to-workspace-up; }
        Mod+Ctrl+D { move-window-to-workspace-down; }

        // ── Fullscreen ──
        Mod+F { fullscreen-window; }

        // ── Screenshot ──
        Print { screenshot; }

        // ── Layout ──
        Mod+Period { consume-window-into-column; }
        Mod+Comma { expel-window-from-column; }
        Mod+Shift+Left { focus-monitor-left; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+Up { focus-monitor-up; }
        Mod+Shift+Down { focus-monitor-down; }
        Mod+Ctrl+Shift+Left { move-column-to-monitor-left; }
        Mod+Ctrl+Shift+Right { move-column-to-monitor-right; }
        Mod+Ctrl+Shift+Up { move-column-to-monitor-up; }
        Mod+Ctrl+Shift+Down { move-column-to-monitor-down; }
        Mod+Minus { set-column-width "-5%"; }
        Mod+Plus { set-column-width "+5%"; }
        Mod+Shift+Minus { set-window-height "-5%"; }
        Mod+Shift+Plus { set-window-height "+5%"; }
    }

    // 最近窗口切换器（niri 内置默认值，显式写入便于版本管理）
    // Mod+grave = Mod+`，filter="app-id" 表示只在当前应用的窗口之间切换。
    recent-windows {
        binds {
            Alt+Tab         { next-window; }
            Alt+Shift+Tab   { previous-window; }
            Alt+grave       { next-window     filter="app-id"; }
            Alt+Shift+grave { previous-window filter="app-id"; }

            Mod+Tab         { next-window; }
            Mod+Shift+Tab   { previous-window; }
            Mod+grave       { next-window     filter="app-id"; }
            Mod+Shift+grave { previous-window filter="app-id"; }
        }
    }
  '';

  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  services.libinput.touchpad.naturalScrolling = true;
}
