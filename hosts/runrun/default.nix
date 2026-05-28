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
    ../../system/desktop/noctalia.nix
    ../../system/hardware/bluetooth.nix
    ../../system/hardware/audio.nix
    ../../system/hardware/power.nix
    ../../system/services/printing.nix
    ../../system/services/samba.nix
    ../../system/services/hermes-agent.nix
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
    moonlight-qt
  ];

  system.stateVersion = "25.11";

  # runrun 专属：当前 VGA 外接屏 EDID 读取失败时，内核只暴露 1024x768。
  # 必须写入 /etc/niri/config.kdl（系统 niri 配置），不能写 ~/.config/niri/config.kdl；
  # 否则 niri 会优先读取用户配置，导致公共 binds 整段失效。
  environment.etc."niri/config.kdl".text = pkgs.lib.mkAfter ''
    output "VGA-1" {
        mode custom=true "1920x1080@60"
        modeline 172.80 1920 2040 2248 2576 1080 1081 1084 1118 "-hsync" "+vsync"
        scale 1.0
    }
  '';
}
