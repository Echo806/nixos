{ config, pkgs, ... }:

{
  services.xserver.enable = true;

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
  '';

  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  services.libinput.touchpad.naturalScrolling = true;
}
