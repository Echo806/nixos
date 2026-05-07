# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/input/fcitx5.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 使用 LTS 内核
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # 禁用 systemd-based initrd，使用旧版 bash init
  # systemd 260 在 ThinkPad X250 Broadwell 上 initrd 阶段崩溃
  boot.initrd.systemd.enable = false;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  networking.proxy.default = "http://127.0.0.1:7897/";
  networking.proxy.noProxy = "127.0.0.1,localhost";

  # Enable networking
  networking.networkmanager.enable = true;

  # Noctalia 面板功能所需的后台服务
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # 启用 Flakes 特性以及配套的船新 nix 命令行工具
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Set your time zone.
  time.timeZone = "Asia/Hong_Kong";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  # Enable the X11 windowing system (required for XWayland).
  services.xserver.enable = true;

  # Electron 应用 Wayland 原生支持（QQ/微信等）
  # 设置后 Electron 应用通过 --ozone-platform-hint=auto 在 Wayland 上原生运行
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # SDDM display manager — 登录后选择 niri 会话
  services.displayManager.sddm.enable = true;

  # PAM: 登录时自动解锁 gnome-keyring（NetworkManager 存储 WiFi 密码）
  security.pam.services.sddm.enableGnomeKeyring = true;

  # 禁用 KDE Plasma, 改用 niri + Noctalia
  # services.desktopManager.plasma6.enable = true;

  # 注册 niri 会话到 display manager
  services.displayManager.sessionPackages = [ pkgs.niri ];

  # niri 系统级注册
  programs.niri.enable = true;

  # niri 配置文件 — 写入 /etc/niri/config.kdl（系统级 fallback 路径）
  # 不依赖 home-manager 用户级激活，避免 dotfiles symlink 冲突
  environment.etc."niri/config.kdl".text = ''
    // 自启动
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "noctalia-shell"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "polkit-gnome-authentication-agent-1"
    spawn-at-startup "nm-applet"

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

        // ── Launch ──
        Mod+T { spawn "alacritty"; }
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.run = {
    isNormalUser = true;
    description = "run";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      clash-verge-rev
    #  thunderbird
    ];
  };

  # CJK 中文字体，解决 splayer 等 Electron 应用汉字不显示问题
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # 将 CJK 字体加入 sans-serif 别名，确保 Chromium/Electron 能正确回退
  fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];

  # Install firefox.
  programs.firefox.enable = true;
  # Enable Steam with 32-bit OpenGL support
  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [
    noto-fonts-cjk-sans
    wqy_microhei
  ];
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    polkit_gnome  # polkit 认证代理
    networkmanagerapplet  # WiFi 密码管理（niri 必需——否则 NM 找不到 secret agent）
    gnome-keyring  # 存储 WiFi 密码
    xwayland-satellite  # niri XWayland 支持（微信等 Qt/X11 应用需要）
  ];


  nix.settings = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://attic.xuyh0120.win/lantian"
      "https://noctalia.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  programs.clash-verge.enable = true;



  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
#   networking.firewall.allowedTCPPorts = [ ... ];
#   networking.firewall.allowedUDPPorts = [ ... ];
#   Or disable the firewall altogether.
#   networking.firewall.enable = ;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
