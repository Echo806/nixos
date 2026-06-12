{ config, pkgs, inputs, ... }:
let
  fonts = import ../../assets/fonts { inherit pkgs; };
in
{
  imports = [
    ./hardware.nix
    ../../system/base/sudo-askpass.nix
    ../../system/base/users.nix
    ../../system/base/locale.nix
    ../../system/base/nix-settings.nix
    ../../system/base/fonts.nix
    ../../system/desktop/niri.nix
    ../../system/desktop/clipboard-bridge.nix
    ../../system/desktop/noctalia.nix
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/audio.nix
    ../../system/hardware/power.nix
    ../../system/services/printing.nix
    ../../system/services/sshfs.nix
    ../../system/services/samba.nix
    ../../hermes
    ../../system/services/office-tools.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LTS 内核
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # 禁用 systemd-based initrd（ThinkPad X250 Broadwell 上崩溃）
  boot.initrd.systemd.enable = false;

  # Networking
  networking.hostName = "runrun";
  networking.proxy.default = "http://127.0.0.1:7897/";
  networking.proxy.noProxy = "127.0.0.1,localhost";
  networking.networkmanager.enable = true;

  # System-level programs
  programs.steam.enable = true;
  programs.steam.fontPackages = fonts.steam;
  programs.clash-verge.enable = true;

  services.tailscale.enable = true;

  # Removable drives in file managers (Nautilus/GVfs uses udisks2 to mount USB disks).
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };


  environment.systemPackages = with pkgs; [
    wget
    git
    polkit_gnome
    networkmanagerapplet
    gnome-keyring
    xwayland-satellite
    wl-clipboard
    xclip

    # Android TV 开发
    android-studio
    android-tools          # adb / fastboot
    jdk21                  # Android Gradle Plugin 需要 JDK 21
  ];

  system.stateVersion = "25.11";

  # runrun 专属：当前 VGA 外接屏 EDID 读取失败时，内核只暴露 1024x768。
  # 之前强制写入 1920x1080 modeline，但日志显示 niri 在创建 DRM compositor 时失败：
  # "Error testing state" / "No space left on device"，导致没有可用 output，桌面黑屏。
  # 先不要强制自定义 1080p，让 niri 使用内核探测到的 1024x768，优先保证能进桌面。
  # 如果之后需要恢复 1080p，应换一条 VGA/转接线或先确认该屏幕真实 modeline。

}
